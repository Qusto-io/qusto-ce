#!/bin/bash
################################################################################
# Week 5 Automation Orchestrator
# Master script for coordinating Tasks 5.1-5.4 execution
#
# Usage:
#   ./orchestrator.sh --task 5.1.1               # Execute specific task
#   ./orchestrator.sh --task 5.4.3 --dry-run     # Preview changes
#   ./orchestrator.sh --status                   # Show progress
#   ./orchestrator.sh --rollback --task 5.2.1    # Rollback specific task
#   ./orchestrator.sh --validate-all             # Run all validations
#
# Version: 1.0
# Date: February 3, 2026
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Log file
LOG_FILE="$PROJECT_ROOT/logs/week5-automation-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$PROJECT_ROOT/logs"

################################################################################
# Logging Functions
################################################################################

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "${BLUE}$@${NC}"
}

log_success() {
    log "SUCCESS" "${GREEN}$@${NC}"
}

log_warning() {
    log "WARNING" "${YELLOW}$@${NC}"
}

log_error() {
    log "ERROR" "${RED}$@${NC}"
}

################################################################################
# Safety Checks
################################################################################

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if in git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi

    # Check if on feature branch
    local branch=$(git branch --show-current)
    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "develop" ]]; then
        log_error "Cannot run on main/master/develop branch"
        log_error "Current branch: $branch"
        log_error "Please create a feature branch: git checkout -b rebrand/week-5-automated"
        exit 1
    fi

    # Check if working directory is clean (unless --force)
    if [[ "$FORCE" != "true" ]]; then
        if ! git diff-index --quiet HEAD --; then
            log_warning "Working directory has uncommitted changes"
            log_warning "Use --force to proceed anyway"
            exit 1
        fi
    fi

    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        log_error "Node.js not found. Please install Node.js"
        exit 1
    fi

    # Check if npm dependencies are installed
    if [ ! -d "$PROJECT_ROOT/assets/node_modules" ]; then
        log_warning "Node modules not found. Running npm install..."
        cd "$PROJECT_ROOT/assets" && npm install
    fi

    log_success "Prerequisites check passed"
}

################################################################################
# Task Execution Functions
################################################################################

execute_task() {
    local task_id=$1
    local dry_run=$2

    log_info "Executing Task $task_id..."

    # Create checkpoint before execution
    create_checkpoint "$task_id"

    # Execute appropriate script
    case "$task_id" in
        5.1.1)
            "$SCRIPT_DIR/task-5.1.1-css-variables.sh" "$dry_run"
            ;;
        5.1.2)
            "$SCRIPT_DIR/task-5.1.2-shadow-utilities.sh" "$dry_run"
            ;;
        5.1.3)
            "$SCRIPT_DIR/task-5.1.3-button-classes.sh" "$dry_run"
            ;;
        5.2.1)
            "$SCRIPT_DIR/task-5.2.1-chart-enhancements.sh" "$dry_run"
            ;;
        5.2.2)
            "$SCRIPT_DIR/task-5.2.2-revenue-badge.sh" "$dry_run"
            ;;
        5.2.3)
            "$SCRIPT_DIR/task-5.2.3-ai-badge.sh" "$dry_run"
            ;;
        5.2.4)
            "$SCRIPT_DIR/task-5.2.4-card-components.sh" "$dry_run"
            ;;
        5.2.5)
            "$SCRIPT_DIR/task-5.2.5-table-enhancements.sh" "$dry_run"
            ;;
        5.3.1)
            "$SCRIPT_DIR/task-5.3.1-revenue-section.sh" "$dry_run"
            ;;
        5.3.2)
            "$SCRIPT_DIR/task-5.3.2-funnel-viz.sh" "$dry_run"
            ;;
        5.3.3)
            "$SCRIPT_DIR/task-5.3.3-cart-alerts.sh" "$dry_run"
            ;;
        5.4.1)
            "$SCRIPT_DIR/task-5.4.1-text-replacement.sh" "$dry_run"
            ;;
        5.4.2)
            "$SCRIPT_DIR/task-5.4.2-asset-replacement.sh" "$dry_run"
            ;;
        5.4.3)
            "$SCRIPT_DIR/task-5.4.3-color-migration.sh" "$dry_run"
            ;;
        *)
            log_error "Unknown task: $task_id"
            exit 1
            ;;
    esac

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "Task $task_id completed successfully"
        record_success "$task_id"
    else
        log_error "Task $task_id failed with exit code $exit_code"
        exit $exit_code
    fi
}

################################################################################
# Checkpoint Management
################################################################################

create_checkpoint() {
    local task_id=$1
    local checkpoint_name="checkpoint-task-$task_id-$(date +%Y%m%d-%H%M%S)"

    log_info "Creating checkpoint: $checkpoint_name"
    git add -A
    git commit -m "checkpoint: Before executing Task $task_id" --allow-empty || true
    git tag -a "$checkpoint_name" -m "Checkpoint before executing Task $task_id"

    log_success "Checkpoint created: $checkpoint_name"
}

################################################################################
# Rollback Functions
################################################################################

rollback_task() {
    local task_id=$1

    log_warning "Rolling back Task $task_id..."

    # Find most recent checkpoint for this task
    local checkpoint=$(git tag -l "checkpoint-task-$task_id-*" | sort -r | head -n 1)

    if [ -z "$checkpoint" ]; then
        log_error "No checkpoint found for Task $task_id"
        exit 1
    fi

    log_info "Found checkpoint: $checkpoint"
    log_warning "This will reset to: $checkpoint"

    read -p "Are you sure you want to rollback? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Rollback cancelled"
        exit 0
    fi

    git reset --hard "$checkpoint"
    log_success "Rolled back to $checkpoint"
}

################################################################################
# Status & Progress Tracking
################################################################################

show_status() {
    log_info "Week 5 Automation Status"
    echo ""

    local progress_file="$PROJECT_ROOT/.week5-progress.json"

    if [ ! -f "$progress_file" ]; then
        log_warning "No progress file found. No tasks have been executed yet."
        echo ""
        echo "Available tasks:"
        echo "  Task 5.1: CSS Foundation & Brand Implementation"
        echo "    5.1.1: Update CSS Variables"
        echo "    5.1.2: Create Shadow Utilities"
        echo "    5.1.3: Enhanced Button Classes"
        echo ""
        echo "  Task 5.2: Component Enhancement"
        echo "    5.2.1: Enhance Line Graph Component"
        echo "    5.2.2: Revenue Badge Component"
        echo "    5.2.3: AI Search Badge Component"
        echo "    5.2.4: Enhanced Card Wrapper"
        echo "    5.2.5: Table Hover Enhancement"
        echo ""
        echo "  Task 5.3: E-commerce Visual Language"
        echo "    5.3.1: Revenue Dashboard Section"
        echo "    5.3.2: Funnel Visualization"
        echo "    5.3.3: Cart Abandonment Alerts"
        echo ""
        echo "  Task 5.4: Application Rebranding"
        echo "    5.4.1: Text Replacement"
        echo "    5.4.2: Visual Asset Replacement"
        echo "    5.4.3: Color Scheme Migration"
        return
    fi

    cat "$progress_file"
}

record_success() {
    local task_id=$1
    local progress_file="$PROJECT_ROOT/.week5-progress.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Initialize progress file if it doesn't exist
    if [ ! -f "$progress_file" ]; then
        echo '{"completed_tasks": []}' > "$progress_file"
    fi

    # Add task to completed list (using simple append, not JSON parsing)
    echo "Task $task_id completed at $timestamp" >> "$progress_file"
}

################################################################################
# Validation Functions
################################################################################

validate_all() {
    log_info "Running all validation checkpoints..."

    "$SCRIPT_DIR/validate.sh" --checkpoint css-variables
    "$SCRIPT_DIR/validate.sh" --checkpoint color-migration
    "$SCRIPT_DIR/validate.sh" --checkpoint logos
    "$SCRIPT_DIR/validate.sh" --checkpoint text
    "$SCRIPT_DIR/validate.sh" --checkpoint production-ready

    log_success "All validations completed"
}

################################################################################
# Main Script
################################################################################

# Parse command line arguments
TASK=""
DRY_RUN=""
ROLLBACK=false
STATUS=false
VALIDATE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --rollback)
            ROLLBACK=true
            shift
            ;;
        --status)
            STATUS=true
            shift
            ;;
        --validate-all)
            VALIDATE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            echo "Week 5 Automation Orchestrator"
            echo ""
            echo "Usage:"
            echo "  ./orchestrator.sh --task 5.1.1               # Execute specific task"
            echo "  ./orchestrator.sh --task 5.4.3 --dry-run     # Preview changes"
            echo "  ./orchestrator.sh --status                   # Show progress"
            echo "  ./orchestrator.sh --rollback --task 5.2.1    # Rollback specific task"
            echo "  ./orchestrator.sh --validate-all             # Run all validations"
            echo "  ./orchestrator.sh --force                    # Skip safety checks"
            echo ""
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution flow
log_info "Week 5 Automation Orchestrator - Starting"
log_info "Project root: $PROJECT_ROOT"
log_info "Log file: $LOG_FILE"
echo ""

if [ "$STATUS" = true ]; then
    show_status
    exit 0
fi

if [ "$VALIDATE" = true ]; then
    validate_all
    exit 0
fi

if [ "$ROLLBACK" = true ]; then
    if [ -z "$TASK" ]; then
        log_error "Please specify --task with --rollback"
        exit 1
    fi
    rollback_task "$TASK"
    exit 0
fi

if [ -z "$TASK" ]; then
    log_error "Please specify a task with --task"
    echo "Use --help for usage information"
    exit 1
fi

# Run prerequisites check
check_prerequisites

# Execute the task
execute_task "$TASK" "$DRY_RUN"

log_success "Orchestrator completed successfully"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Test changes: mix test && cd assets && npm test"
echo "  3. Commit changes: git add . && git commit -m 'feat: complete Task $TASK'"
echo "  4. Continue to next task or run --status to see progress"
echo ""
