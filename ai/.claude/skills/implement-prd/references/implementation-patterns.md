# Implementation Patterns

Reference patterns for common SDD constructs by language/stack. Consult this file
when the generator pass needs to match project conventions for a specific technology.

---

## REST API handlers

### Rust / Axum

```rust
// Route registration
let app = Router::new()
    .route("/auth/register", post(register_handler))
    .layer(AuthLayer::new(jwt_secret));

// Handler
async fn register_handler(
    State(db): State<DbPool>,
    Json(body): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<RegisterResponse>), AppError> {
    // validate → service call → response
}
```

SDD error table mapping (Axum):
| SDD condition | StatusCode |
|---|---|
| invalid input | `StatusCode::BAD_REQUEST` (400) |
| unauthorized | `StatusCode::UNAUTHORIZED` (401) |
| forbidden | `StatusCode::FORBIDDEN` (403) |
| not found | `StatusCode::NOT_FOUND` (404) |
| conflict | `StatusCode::CONFLICT` (409) |
| downstream failure | `StatusCode::SERVICE_UNAVAILABLE` (503) |

### TypeScript / Express

```typescript
router.post('/auth/register', validate(registerSchema), async (req, res, next) => {
  try {
    const user = await authService.register(req.body);
    res.status(201).json(user);
  } catch (err) {
    next(err); // centralised error handler maps AppError → HTTP status
  }
});
```

### Go / net/http or Gin

```go
r.POST("/auth/register", func(c *gin.Context) {
    var body RegisterRequest
    if err := c.ShouldBindJSON(&body); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    result, err := svc.Register(c.Request.Context(), body)
    if err != nil {
        handleError(c, err) // maps domain errors to HTTP
        return
    }
    c.JSON(201, result)
})
```

---

## Data models / migrations

### SQL (PostgreSQL)

Always include:
- Primary key as `BIGSERIAL` or `UUID DEFAULT gen_random_uuid()`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` + trigger or application-level update
- Explicit constraints and indexes named after the table (`accounts_email_uniq`)
- Migration file in `db/migrations/` named `<seq>_<description>.sql`

```sql
-- 001_create_accounts.sql
CREATE TABLE accounts (
    id          BIGSERIAL PRIMARY KEY,
    email       TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT accounts_email_uniq UNIQUE (email)
);

CREATE INDEX accounts_email_idx ON accounts (email);
```

### Rust / SQLx migrations

Place in `migrations/` — SQLx discovers these automatically.
Use `sqlx::query_as!` macro for type-safe queries.

### TypeScript / Prisma

```prisma
model Account {
  id           Int      @id @default(autoincrement())
  email        String   @unique
  passwordHash String   @map("password_hash")
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt @map("updated_at")

  @@map("accounts")
}
```

Run `prisma migrate dev --name <description>` to generate the migration.

---

## Service layer

A service encapsulates business logic and is independent of HTTP concerns.

```typescript
// auth.service.ts
export class AuthService {
  constructor(private readonly db: Database) {}

  async register(input: RegisterInput): Promise<User> {
    const existing = await this.db.accounts.findByEmail(input.email);
    if (existing) throw new ConflictError('Email already registered');

    const hash = await bcrypt.hash(input.password, 12);
    return this.db.accounts.create({ email: input.email, passwordHash: hash });
  }
}
```

Pattern rules:
- Services throw typed domain errors (`NotFoundError`, `ConflictError`, `UnauthorizedError`)
- HTTP handlers catch domain errors and map to status codes
- Services never import from HTTP layer

---

## Auth middleware

### JWT verification (Express)

```typescript
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED' });

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
    next();
  } catch {
    res.status(401).json({ error: 'INVALID_TOKEN' });
  }
}
```

### Authorization (role check)

```typescript
export function requireRole(role: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (req.user?.role !== role) {
      return res.status(403).json({ error: 'FORBIDDEN' });
    }
    next();
  };
}
```

---

## Input validation

### TypeScript / Zod

```typescript
const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
});

// Middleware
function validate(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ error: 'INVALID_INPUT', details: result.error.issues });
    }
    req.body = result.data;
    next();
  };
}
```

### Rust / validator crate

```rust
#[derive(Debug, Deserialize, Validate)]
struct RegisterRequest {
    #[validate(email)]
    email: String,
    #[validate(length(min = 8, max = 128))]
    password: String,
}
```

---

## System test patterns

### REST API tests (TypeScript / supertest)

```typescript
describe('POST /auth/register', () => {
  it('returns 201 and user id on valid input', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ email: 'test@example.com', password: 'securepassword' });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body).not.toHaveProperty('passwordHash');
  });

  it('returns 400 when email is missing', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ password: 'securepassword' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('INVALID_INPUT');
  });

  it('returns 409 on duplicate email', async () => {
    await request(app).post('/auth/register')
      .send({ email: 'dup@example.com', password: 'securepassword' });

    const res = await request(app).post('/auth/register')
      .send({ email: 'dup@example.com', password: 'anotherpassword' });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('EMAIL_TAKEN');
  });
});
```

### Rust / axum test client

```rust
#[tokio::test]
async fn register_returns_201_on_valid_input() {
    let app = test_app().await;
    let client = TestClient::new(app);

    let res = client.post("/auth/register")
        .json(&json!({"email": "test@example.com", "password": "securepassword"}))
        .await;

    assert_eq!(res.status(), StatusCode::CREATED);
    let body: Value = res.json().await;
    assert!(body["id"].is_number());
}
```

### Database teardown

Always clean up test data between tests. Use a transaction that rolls back, a dedicated test database, or `beforeEach`/`afterEach` truncation:

```typescript
beforeEach(async () => {
  await db.query('TRUNCATE accounts CASCADE');
});
```

---

## Error response shape

Standardise across the project so tests can assert consistently:

```json
{
  "error": "EMAIL_TAKEN",        // machine-readable code from SDD error table
  "message": "Email already registered",  // human-readable
  "details": []                  // optional validation issue list
}
```

Map SDD "User-Facing Message" column to `message`. Map SDD "Error Code" column to `error`.
