---
description: Reverse-engineer design documentation for a specific area and output in Markdown format
---

You are tasked with reverse-engineering comprehensive design documentation for a specific area of the codebase and outputting it in Markdown format.

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
   - Architecture (component diagrams in ASCII art or Mermaid, interaction flows)
   - Implementation Details (data structures, algorithms, code references)
   - Operational Procedures (how to use, configure, troubleshoot)
   - Design Rationale (why certain choices were made)
   - Future Enhancements (potential improvements)

3. **Use GitHub-flavored Markdown syntax**:
   - Headers: `#`, `##`, `###`, etc.
   - Bold: `**text**`
   - Italic: `*text*`
   - Inline code: `` `code` ``
   - Code blocks: ` ```language ` ... ` ``` `
   - Bullet lists: `- item` or `* item`
   - Numbered lists: `1. item`
   - Tables: `| heading | heading |` with `|---|---|` separator
   - Horizontal rules: `---`
   - Links: `[text](url)` or `[text](#anchor)`
   - Task lists: `- [ ] item` or `- [x] item`

4. **Include practical details**:
   - File paths and line numbers for code references (format: `` `file_path:line_number` ``)
   - Mermaid diagrams for architecture and flows (use ` ```mermaid ` code blocks)
   - ASCII diagrams as fallback (in regular code blocks)
   - Example configurations and commands
   - Common troubleshooting scenarios

5. **Structure the document** with:
   - Clear table of contents with anchor links (e.g., `[Section Name](#section-name)`)
   - Logical section progression
   - Code examples with proper syntax highlighting (specify language after ` ``` `)
   - Tables for reference information
   - Appendices for glossary and file references

## Output Format

Write the complete design document directly in Markdown format. The document should be ready to copy-paste directly into GitHub, GitLab, or any Markdown-compatible platform.

## Example Usage

User: "Design doc for the SNMP agent implementation"
User: "Document the web server architecture"
User: "Reverse-engineer the flash partition system"

## Notes

- Be thorough and include all relevant technical details
- Prefer Mermaid diagrams when possible (flowcharts, sequence diagrams, class diagrams)
- Use ASCII art as a fallback for complex diagrams that Mermaid cannot represent
- Reference actual file paths and line numbers from the codebase
- Include practical operational procedures and troubleshooting
- Maintain a professional, technical writing style
- Organize information hierarchically for easy navigation