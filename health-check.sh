#!/bin/bash

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/retired-entries.sh"

# Check Homebrew
check_homebrew() {
    print_header "Homebrew Package Manager"
    if command_exists brew; then
        local version
        version=$(brew --version | head -n1 | awk '{print $2}')
        print_success "Homebrew installed (version $version)"
        
        # Check if Homebrew is up to date
        local outdated
        outdated=$(brew outdated 2>/dev/null | wc -l | xargs)
        if [ "$outdated" -gt 0 ]; then
            print_warning "$outdated outdated package(s) found. Run 'brew upgrade' to update"
        else
            print_info "All Homebrew packages are up to date"
        fi
    else
        print_fail "Homebrew not installed"
        print_info "Run './install.sh' to install Homebrew"
    fi
}

check_brewfile_tools() {
    print_header "Brewfile Tools"
    local installed formula version
    installed="$(installed_formulae)"

    for formula in $(brewfile_formulae "$REPO_DIR/Brewfile"); do
        version="$(formula_version "$installed" "$formula")"
        if [ -n "$version" ]; then
            print_success "$formula installed ($version)"
        else
            print_fail "$formula not installed"
            print_info "Run './install.sh --only-tools'"
        fi
    done
}

check_swiftformat_config() {
    print_header "SwiftFormat Configuration"
    if [ -f "$HOME/.swiftformat" ]; then
        print_success "SwiftFormat configuration file found at ~/.swiftformat"
    else
        print_fail "SwiftFormat configuration file not found"
        print_info "Run './install.sh --only-swiftformat-config' to install it"
    fi
}

# Check JetBrains Mono Nerd Font
check_font() {
    print_header "JetBrains Mono Nerd Font"
    local font_count
    font_count=$(nerd_font_files | wc -l | xargs)

    if [ "$font_count" -gt 0 ]; then
        print_success "JetBrains Mono Nerd Font installed ($font_count font files)"
        nerd_font_cask_installed || print_info "Installed by hand: './update.sh' can't upgrade it"
        print_info "Select it in your terminal profile if icons render as boxes"
    else
        print_fail "JetBrains Mono Nerd Font not found"
        print_info "Run './install.sh --only-font' to install the font"
    fi
}

# Check shell aliases
check_aliases() {
    print_header "Shell Aliases"
    local zshrc_file="$HOME/.zshrc"
    local aliases_file="$HOME/.config/aliases.zsh"

    if [ ! -f "$zshrc_file" ]; then
        print_fail ".zshrc file not found"
        print_info "Create a .zshrc file and run './install.sh'"
        return
    fi

    local alias_source=""

    if [ -f "$aliases_file" ]; then
        alias_source="$aliases_file"

        if grep -q "source.*aliases.zsh" "$zshrc_file"; then
            print_success "Shell aliases sourced from ~/.config/aliases.zsh"
        else
            print_fail "Aliases file exists but is not sourced in .zshrc"
            print_info "Run './install.sh --only-aliases' to add the source line"
        fi
    elif grep -q "# Git aliases" "$zshrc_file"; then
        alias_source="$zshrc_file"
        print_success "Shell aliases configured inline in .zshrc"
        print_info "Run './install.sh --only-aliases' to migrate them to ~/.config/aliases.zsh"
    else
        print_fail "Shell aliases not found"
        print_info "Run './install.sh' to add aliases"
        return
    fi

    local alias_count

    alias_count=$(grep -c "^alias" "$alias_source" | xargs)
    print_info "Found $alias_count aliases"

    for alias_name in gl gp gst gc ll la; do
        if grep -q "alias $alias_name=" "$alias_source"; then
            print_info "  ✓ $alias_name configured"
        else
            print_warning "  ✗ $alias_name not found"
        fi
    done
}

# Check custom scripts
check_scripts() {
    print_header "Custom Scripts"
    local bin_dir="$HOME/Developer/bin"
    
    if [ -d "$bin_dir" ]; then
        print_success "Scripts directory exists at ~/Developer/bin"
        
        # Check for deeplink script
        if [ -f "$bin_dir/deeplink.sh" ]; then
            if [ -x "$bin_dir/deeplink.sh" ]; then
                print_success "deeplink.sh installed and executable"
            else
                print_warning "deeplink.sh found but not executable"
                print_info "Run 'chmod +x $bin_dir/deeplink.sh'"
            fi
        else
            print_fail "deeplink.sh not found"
            print_info "Run './install.sh' to install custom scripts"
        fi
    else
        print_fail "Scripts directory not found"
        print_info "Run './install.sh' to create and populate ~/Developer/bin"
    fi
}

# Check Xcode themes
check_xcode_themes() {
    print_header "Xcode Color Themes"
    local themes_dir="$XC_USER_DATA/FontAndColorThemes"
    
    if [ -d "$themes_dir" ]; then
        local theme_count
        theme_count=$(ls "$themes_dir"/*.xccolortheme 2>/dev/null | wc -l | xargs)
        if [ "$theme_count" -gt 0 ]; then
            print_success "Xcode themes directory found with $theme_count theme(s)"
            
            # Check for specific custom themes
            for theme in "Alfred Dark" "Alfred Light"; do
                if [ -f "$themes_dir/$theme.xccolortheme" ]; then
                    print_info "  ✓ $theme.xccolortheme installed"
                fi
            done
        else
            print_warning "Themes directory exists but no themes found"
            print_info "Run './install.sh' to install themes"
        fi
    else
        print_fail "Xcode themes directory not found"
        print_info "Run './install.sh' to create and install themes"
    fi
}

# Check Xcode templates
check_xcode_templates() {
    print_header "Xcode Templates"
    local templates_dir="$XC_DIR/Templates"
    
    if [ -d "$templates_dir" ]; then
        local template_count
        template_count=$(find "$templates_dir" -name "*.xctemplate" 2>/dev/null | wc -l | xargs)
        if [ "$template_count" -gt 0 ]; then
            print_success "Xcode templates found ($template_count template(s))"
        else
            print_warning "Templates directory exists but no templates found"
            print_info "Run './install.sh' to install templates"
        fi
    else
        print_fail "Xcode templates directory not found"
        print_info "Run './install.sh' to create and install templates"
    fi
}

# Check Xcode header template
check_xcode_header() {
    print_header "Xcode Header Template"
    local header_file="$XC_USER_DATA/IDETemplateMacros.plist"
    
    if [ -f "$header_file" ]; then
        print_success "Xcode header template found"
        
        # Check if it contains custom content
        if grep -q "FILEHEADER" "$header_file" 2>/dev/null; then
            print_info "Custom header configuration detected"
        fi
    else
        print_fail "Xcode header template not found"
        print_info "Run './install.sh' to install header template"
    fi
}

# Check Claude Code configuration
check_claude_config() {
    print_header "Claude Code Configuration"
    local claude_dir="$HOME/.claude"
    local claude_config="$claude_dir/CLAUDE.md"
    
    if [ -f "$claude_config" ]; then
        print_success "Claude Code configuration found at ~/.claude/CLAUDE.md"
        
        # Check file size to ensure it's not empty
        local file_size
        file_size=$(wc -c < "$claude_config" | xargs)
        if [ "$file_size" -gt 100 ]; then
            print_info "Configuration file size: $file_size bytes"
        else
            print_warning "Configuration file seems too small ($file_size bytes)"
        fi
    else
        print_fail "Claude Code configuration not found"
        print_info "Run './install.sh' to install Claude configuration"
    fi
}

# Check Claude agents
check_claude_agents() {
    print_header "Claude Agents"
    local agents_dir="$HOME/.claude/agents"
    
    if [ -d "$agents_dir" ]; then
        local agent_count
        agent_count=$(ls "$agents_dir"/*.md 2>/dev/null | wc -l | xargs)
        if [ "$agent_count" -gt 0 ]; then
            print_success "Claude agents directory found with $agent_count agent(s)"
            
            # List agents
            for agent_file in "$agents_dir"/*.md; do
                if [ -f "$agent_file" ]; then
                    local agent_name
                    agent_name=$(basename "$agent_file" .md)
                    print_info "  ✓ $agent_name"
                fi
            done
        else
            print_warning "Agents directory exists but no agents found"
            print_info "Run './install.sh' to install agents"
        fi
    else
        print_fail "Claude agents directory not found"
        print_info "Run './install.sh' to create and install agents"
    fi
    check_retired_entries "claude/agents" "$agents_dir" "agent"
}

check_retired_entries() {
    local subdir="$1"
    local dest="$2"
    local label="$3"
    local name

    while read -r name; do
        [ -e "$dest/$name" ] || continue
        print_warning "Claude $label deleted from the repo is still installed: $name"
        print_info "Run './install.sh --only-claude' to remove it"
    done < <(retired_repo_entries "$REPO_DIR" "$subdir")
}

# Check Claude skills
check_claude_skills() {
    print_header "Claude Skills"
    local skills_dir="$HOME/.claude/skills"
    local tracked=false

    for skill in "$REPO_DIR"/claude/skills/*/; do
        [ -d "$skill" ] || continue
        tracked=true
        local skill_name
        skill_name="$(basename "$skill")"
        if [ -f "$skills_dir/$skill_name/SKILL.md" ]; then
            print_success "Claude skill installed: $skill_name"
        else
            print_fail "Claude skill not installed: $skill_name"
            print_info "Run './install.sh --only-claude' to install it"
        fi
    done

    $tracked || print_info "No Claude skills tracked in the repo"
    check_retired_entries "claude/skills" "$skills_dir" "skill"
}

# Check for Xcode installation
check_xcode() {
    print_header "Xcode"
    if command_exists xcodebuild; then
        local xcode_version
        xcode_version=$(xcodebuild -version | head -n1)
        print_success "Xcode installed ($xcode_version)"
    else
        print_warning "Xcode or Command Line Tools not found"
        print_info "Some features may not work without Xcode"
    fi
}

# Check Git configuration
check_git() {
    print_header "Git Configuration"
    if command_exists git; then
        local git_version
        git_version=$(git --version | awk '{print $3}')
        print_success "Git installed (version $git_version)"
        
        # Check Git user configuration
        local git_user
        git_user=$(git config --global user.name 2>/dev/null)
        local git_email
        git_email=$(git config --global user.email 2>/dev/null)
        
        if [ -n "$git_user" ]; then
            print_info "Git user: $git_user"
        else
            print_warning "Git user.name not configured"
            print_info "Run 'git config --global user.name \"Your Name\"'"
        fi
        
        if [ -n "$git_email" ]; then
            print_info "Git email: $git_email"
        else
            print_warning "Git user.email not configured"
            print_info "Run 'git config --global user.email \"your@email.com\"'"
        fi
    else
        print_fail "Git not installed"
        print_info "Install Git via Homebrew: 'brew install git'"
    fi
}

# Print summary
print_summary() {
    print_header "Health Check Summary"
    
    local total
    
    total=$((SUCCEEDED + FAILED + WARNINGS))
    local health_percentage
    health_percentage=$((SUCCEEDED * 100 / total))
    
    echo -e "\n${WHITE}Results:${NC}"
    echo -e "  ${GREEN}✓ Passed:${NC}   $SUCCEEDED"
    echo -e "  ${RED}✗ Failed:${NC}   $FAILED"
    echo -e "  ${YELLOW}! Warnings:${NC} $WARNINGS"
    echo -e "  ${CYAN}━ Total:${NC}    $total"
    
    echo -e "\n${WHITE}Health Score: ${NC}"
    if [ "$health_percentage" -ge 90 ]; then
        echo -e "  ${GREEN}$health_percentage%${NC} - Excellent! 🎉"
    elif [ "$health_percentage" -ge 70 ]; then
        echo -e "  ${YELLOW}$health_percentage%${NC} - Good, but some issues need attention"
    elif [ "$health_percentage" -ge 50 ]; then
        echo -e "  ${YELLOW}$health_percentage%${NC} - Fair, several components need attention"
    else
        echo -e "  ${RED}$health_percentage%${NC} - Poor, run './install.sh' to fix issues"
    fi
    
    echo -e "\n${CYAN}💡 Recommendations:${NC}"
    if [ "$FAILED" -gt 0 ]; then
        echo -e "  • Run ${WHITE}./install.sh${NC} to install missing components"
    fi
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "  • Review warnings above and take suggested actions"
    fi
    if command_exists brew && [ "$(brew outdated 2>/dev/null | wc -l | xargs)" -gt 0 ]; then
        echo -e "  • Run ${WHITE}brew upgrade${NC} to update outdated packages"
    fi
    if [ "$health_percentage" -eq 100 ]; then
        echo -e "  • Everything looks perfect! Keep coding! 🚀"
    fi
}

# Main execution
print_banner "🏥 Development Environment Health Check"
print_info "Starting health check...\n"

check_homebrew
check_brewfile_tools
check_swiftformat_config
check_font
check_aliases
check_scripts
check_xcode
check_xcode_themes
check_xcode_templates
check_xcode_header
check_claude_config
check_claude_agents
check_claude_skills
check_git

print_summary

echo -e "\n${GREEN}Health check complete! 🏥${NC}\n"
