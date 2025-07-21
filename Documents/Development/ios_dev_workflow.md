# iOS Development Workflow Protocol

## Objective
Execute a complete development cycle from build verification to feature implementation with continuous momentum.

## Workflow Stages

### Stage 1: Build Verification & Deployment
**Build & Test**
- Use `mcpxcodebuild` to build the Xcode project from the `.xcodeproj` file
- Launch the app on iOS Simulator
- Verify successful build and runtime execution
- Document any build warnings or issues encountered
- screenshot the app dashboard and community tabs

**Version Control**
- If build succeeds: commit all changes to GitHub with descriptive commit message
- If build fails: document failure reasons and halt workflow until resolved

### Stage 2: Knowledge Capture & Process Improvement
**Update Documentation**
- Analyze the entire development session for insights
- Update `lessons-learned.md` with:
  - Build/deployment challenges encountered and solutions
  - Code quality improvements identified
  - Architectural decisions and their rationale
  - Performance optimizations discovered
  - Common pitfalls to avoid in future iterations
  - SwiftUI/Swift best practices reinforced
  - TDD and MVVM implementation insights

### Stage 3: Continuous Development
**Next Implementation Cycle**
- Proceed immediately to implement next deliverables
- Apply TDD and MVVM patterns consistently
- Follow SwiftUI Code Style and Conventions Standards
- Maintain architecture-first thinking throughout
- **No permission requests** - maintain development momentum
- Continue until all features are implemented and running

## Success Criteria
**Workflow complete when**: Simulator is running successfully with all new deliverables fully implemented, tested, and documented.

## Error Handling Protocol
- Document all failures with timestamps and context
- Provide specific technical details for debugging
- Update lessons learned even if build fails
- Maintain code quality standards regardless of time pressure

## Core Principles During Execution
1. **Meticulous Code Review**: Double-check every line against best practices
2. **Strict Standards Adherence**: Follow SwiftUI Code Style and Conventions
3. **Architecture-First**: Consider scalability, maintainability, and performance
4. **Security & Performance**: Validate inputs, optimize rendering, use async/await
5. **Comprehensive Testing**: TDD approach with proper test coverage

## Communication Guidelines
- Explain architectural decisions clearly
- Reference specific guideline violations
- Provide corrected code examples
- Focus on long-term maintainability over quick fixes

**Execute with meticulous attention to code quality and architectural integrity.**