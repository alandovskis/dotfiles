---
description: Reverse-engineer design documentation for a specific area and output in Confluence wiki markup
---

You are tasked with reverse-engineering comprehensive design documentation for a specific area of the codebase and outputting it in Confluence wiki markup format.

## Instructions

1. **Analyze the specified area**: Thoroughly explore the codebase area specified by the user using Glob, Grep, and Read tools to understand:
   - Architecture and component relationships
   - Key data structures and APIs
   - Implementation patterns and algorithms
   - Configuration and management approaches
   - Error handling and recovery mechanisms

2. **Generate comprehensive documentation** covering:
   - Executive Summary (overview and key features)
   - System Overview (purpose, design goals, core concepts)
   - Architecture (component diagrams in ASCII art, interaction flows)
   - Implementation Details (data structures, algorithms, code references)
   - Operational Procedures (how to use, configure, troubleshoot)
   - Design Rationale (why certain choices were made)
   - Future Enhancements (potential improvements)

3. **Use Confluence wiki markup syntax**:
   - Headers: `h1.`, `h2.`, `h3.`, etc.
   - Bold: `*text*`
   - Italic: `_text_`
   - Inline code: `{{code}}`
   - Code blocks: `{code:language}` ... `{code}` or just `{code}` ... `{code}`
   - Bullet lists: `* item`
   - Numbered lists: `# item`
   - Tables: `|| heading || heading ||` for headers, `| cell | cell |` for rows
   - Horizontal rules: `----`
   - Links: `[text|url]` or `[text|#anchor]`

4. **Include practical details**:
   - File paths and line numbers for code references (format: `{{file_path:line_number}}`)
   - ASCII diagrams for architecture and flows
   - Example configurations and commands
   - Common troubleshooting scenarios

5. **Structure the document** with:
   - Clear table of contents with anchor links
   - Logical section progression
   - Code examples with proper syntax highlighting
   - Tables for reference information
   - Appendices for glossary and file references

## Output Format

Write the complete design document directly in Confluence wiki markup format. The document should be ready to copy-paste directly into Confluence.

## Example Usage

User: "Design doc for the SNMP agent implementation"
User: "Document the web server architecture"
User: "Reverse-engineer the flash partition system"

## Notes

- Be thorough and include all relevant technical details
- Use ASCII art for diagrams (Confluence will render them in code blocks)
- Reference actual file paths and line numbers from the codebase
- Include practical operational procedures and troubleshooting
- Maintain a professional, technical writing style
- Organize information hierarchically for easy navigation