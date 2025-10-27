#!/usr/bin/env python3
"""
Homelab Task Manager - Dashboard Generator
Generates HTML dashboards from YAML task files
Security: HTML escaping, safe YAML loading, input validation
"""

import os
import sys
import yaml
import html
from datetime import datetime
from pathlib import Path

# Configuration
TASKS_DIR = Path("tasks")
DASHBOARD_DIR = Path("dashboard")
COLUMNS = ["backlog", "todo", "in_progress", "stalled", "done"]
COLUMN_LABELS = {
    "backlog": "Backlog",
    "todo": "To Do",
    "in_progress": "In Progress",
    "stalled": "Stalled",
    "done": "Done"
}

# Priority configuration (no emojis per requirements)
PRIORITY_CONFIG = {
    "urgent": {"order": 4, "color": "#ff6b6b", "label": "Urgent"},
    "high": {"order": 3, "color": "#f85149", "label": "High"},
    "medium": {"order": 2, "color": "#d29922", "label": "Medium"},
    "low": {"order": 1, "color": "#58a6ff", "label": "Low"}
}


def safe_html_escape(text):
    """Safely escape HTML with None handling"""
    if text is None:
        return ""
    return html.escape(str(text))


def load_tasks():
    """Load all tasks from YAML files with comprehensive error handling"""
    tasks = {col: [] for col in COLUMNS}
    errors = []
    
    for column in COLUMNS:
        column_dir = TASKS_DIR / column
        if not column_dir.exists():
            errors.append(f"Warning: Directory {column_dir} does not exist")
            continue
            
        for task_file in column_dir.glob("*.yaml"):
            try:
                with open(task_file, 'r', encoding='utf-8') as f:
                    task_data = yaml.safe_load(f)
                    
                    if not task_data:
                        continue
                    
                    # Security: Escape all user-provided strings
                    task_data['title'] = safe_html_escape(task_data.get('title', 'Untitled'))
                    task_data['description'] = safe_html_escape(task_data.get('description', ''))
                    task_data['category'] = safe_html_escape(task_data.get('category', 'general'))
                    
                    # Validate priority
                    priority = task_data.get('priority', 'medium').lower()
                    if priority not in PRIORITY_CONFIG:
                        priority = 'medium'
                    task_data['priority'] = priority
                    
                    # Handle tags safely
                    tags = task_data.get('tags', [])
                    if isinstance(tags, list):
                        task_data['tags'] = [safe_html_escape(tag) for tag in tags]
                    else:
                        task_data['tags'] = []
                    
                    # Store filename for tracking
                    task_data['filename'] = task_file.name
                    task_data['column'] = column
                    
                    # Determine if task is private
                    task_data['private'] = task_data.get('private', False)
                    
                    tasks[column].append(task_data)
                    
            except yaml.YAMLError as e:
                errors.append(f"Error parsing {task_file}: {str(e)}")
            except Exception as e:
                errors.append(f"Error loading {task_file}: {str(e)}")
    
    # Sort tasks by priority within each column
    for column in tasks:
        tasks[column].sort(
            key=lambda x: PRIORITY_CONFIG[x['priority']]['order'],
            reverse=True
        )
    
    return tasks, errors


def calculate_stats(tasks, include_private=True):
    """Calculate dashboard statistics"""
    total = 0
    by_priority = {p: 0 for p in PRIORITY_CONFIG.keys()}
    by_category = {}
    backlog_count = 0
    todo_count = 0
    active_count = 0
    stalled_count = 0
    done_count = 0
    
    for column, task_list in tasks.items():
        for task in task_list:
            # Skip private tasks if not including them
            if not include_private and task.get('private', False):
                continue
                
            total += 1
            priority = task.get('priority', 'medium')
            by_priority[priority] = by_priority.get(priority, 0) + 1
            
            category = task.get('category', 'general')
            by_category[category] = by_category.get(category, 0) + 1
            
            # Count by column
            if column == 'backlog':
                backlog_count += 1
            elif column == 'todo':
                todo_count += 1
            elif column == 'in_progress':
                active_count += 1
            elif column == 'stalled':
                stalled_count += 1
            elif column == 'done':
                done_count += 1
    
    completion_rate = round((done_count / total * 100) if total > 0 else 0, 1)
    
    return {
        'total': total,
        'backlog': backlog_count,
        'todo': todo_count,
        'active': active_count,
        'stalled': stalled_count,
        'done': done_count,
        'completion_rate': completion_rate,
        'by_priority': by_priority,
        'by_category': by_category
    }


def generate_html(tasks, stats, is_public=False):
    """Generate HTML dashboard"""
    
    title_suffix = " (Public)" if is_public else ""
    watermark = ""
    if is_public:
        watermark = """
        <div style="background: #1f6feb; color: white; padding: 10px; text-align: center; border-radius: 6px; margin-bottom: 20px;">
            Public Dashboard - Showing selected tasks only
        </div>
        """
    
    # Generate statistics cards
    stats_html = f"""
    <div class="stats">
        <div class="stat-card">
            <div class="stat-value">{stats['total']}</div>
            <div class="stat-label">Total Tasks</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['backlog']}</div>
            <div class="stat-label">Backlog</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['todo']}</div>
            <div class="stat-label">To Do</div>
        </div>
        <div class="stat-card stat-active">
            <div class="stat-value">{stats['active']}</div>
            <div class="stat-label">Active</div>
        </div>
        <div class="stat-card stat-stalled">
            <div class="stat-value">{stats['stalled']}</div>
            <div class="stat-label">Stalled</div>
        </div>
        <div class="stat-card stat-done">
            <div class="stat-value">{stats['done']}</div>
            <div class="stat-label">Completed</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['completion_rate']}%</div>
            <div class="stat-label">Completion Rate</div>
        </div>
    </div>
    """
    
    # Generate Kanban columns
    kanban_html = '<div class="kanban">'
    for column in COLUMNS:
        task_list = tasks[column]
        
        # Filter private tasks for public dashboard
        if is_public:
            task_list = [t for t in task_list if not t.get('private', False)]
        
        task_count = len(task_list)
        column_label = COLUMN_LABELS[column]
        
        # Column-specific styling
        column_class = f"column-{column}"
        
        kanban_html += f"""
        <div class="column {column_class}">
            <h2>{column_label} <span style="color: #8b949e;">({task_count})</span></h2>
        """
        
        for task in task_list:
            priority = task.get('priority', 'medium')
            priority_color = PRIORITY_CONFIG[priority]['color']
            priority_label = PRIORITY_CONFIG[priority]['label']
            
            tags_html = ""
            if task.get('tags'):
                tags_html = '<div class="task-meta">'
                for tag in task['tags']:
                    tags_html += f'<span class="tag">{tag}</span>'
                tags_html += '</div>'
            
            description_html = ""
            if task.get('description'):
                description_html = f'<div class="task-description">{task["description"]}</div>'
            
            kanban_html += f"""
            <div class="task-card priority-{priority}">
                <div class="task-title">{task['title']}</div>
                <div style="color: {priority_color}; font-size: 0.85em; margin-top: 5px;">{priority_label}</div>
                {description_html}
                {tags_html}
            </div>
            """
        
        kanban_html += '</div>'
    
    kanban_html += '</div>'
    
    # Full HTML document
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Homelab Task Dashboard{title_suffix}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            padding: 20px;
            line-height: 1.6;
        }}
        .container {{ max-width: 1600px; margin: 0 auto; }}
        header {{ 
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 2px solid #30363d;
        }}
        h1 {{ 
            color: #58a6ff; 
            margin-bottom: 10px;
            font-size: 2em;
        }}
        .subtitle {{ 
            color: #8b949e;
            font-size: 1.1em;
        }}
        .stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }}
        .stat-card {{
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 20px;
            text-align: center;
        }}
        .stat-active {{
            border-left: 4px solid #58a6ff;
        }}
        .stat-stalled {{
            border-left: 4px solid #d29922;
        }}
        .stat-done {{
            border-left: 4px solid #3fb950;
        }}
        .stat-value {{ 
            font-size: 2.5em; 
            font-weight: bold; 
            color: #58a6ff;
            margin-bottom: 8px;
        }}
        .stat-label {{ 
            color: #8b949e;
            font-size: 0.95em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }}
        .kanban {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
        }}
        .column {{
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 20px;
        }}
        .column-stalled {{
            border-top: 3px solid #d29922;
        }}
        .column h2 {{
            color: #58a6ff;
            margin-bottom: 20px;
            font-size: 1.3em;
            padding-bottom: 10px;
            border-bottom: 2px solid #30363d;
        }}
        .column-stalled h2 {{
            color: #d29922;
        }}
        .task-card {{
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 12px;
            transition: all 0.2s ease;
        }}
        .task-card:hover {{ 
            border-color: #58a6ff;
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
            transform: translateY(-2px);
        }}
        .task-title {{ 
            color: #c9d1d9; 
            font-weight: 600;
            font-size: 1.05em;
            margin-bottom: 8px;
            line-height: 1.4;
        }}
        .task-description {{ 
            color: #8b949e; 
            font-size: 0.9em; 
            margin-top: 10px;
            line-height: 1.5;
            padding-top: 10px;
            border-top: 1px solid #30363d;
        }}
        .task-meta {{ 
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            margin-top: 12px;
        }}
        .tag {{
            background: #1f6feb;
            color: #fff;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: 500;
        }}
        .priority-urgent {{ border-left: 4px solid #ff6b6b; }}
        .priority-high {{ border-left: 4px solid #f85149; }}
        .priority-medium {{ border-left: 4px solid #d29922; }}
        .priority-low {{ border-left: 4px solid #58a6ff; }}
        .updated {{ 
            color: #8b949e; 
            font-size: 0.9em; 
            margin-top: 30px;
            text-align: center;
            padding-top: 20px;
            border-top: 1px solid #30363d;
        }}
        @media (max-width: 1200px) {{
            .kanban {{
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            }}
        }}
        @media (max-width: 768px) {{
            .kanban {{
                grid-template-columns: 1fr;
            }}
            .stats {{
                grid-template-columns: repeat(2, 1fr);
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Homelab Task Dashboard{title_suffix}</h1>
            <div class="subtitle">Task Management System</div>
        </header>
        
        {watermark}
        {stats_html}
        {kanban_html}
        
        <div class="updated">
            Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
        </div>
    </div>
</body>
</html>"""
    
    return html_content


def main():
    """Main execution function"""
    try:
        # Ensure dashboard directory exists
        DASHBOARD_DIR.mkdir(exist_ok=True)
        
        # Load all tasks
        print("Loading tasks...")
        tasks, errors = load_tasks()
        
        # Report any errors
        if errors:
            print("\nWarnings/Errors:")
            for error in errors:
                print(f"  - {error}")
        
        # Generate private dashboard (all tasks)
        print("\nGenerating private dashboard...")
        stats_private = calculate_stats(tasks, include_private=True)
        html_private = generate_html(tasks, stats_private, is_public=False)
        
        private_path = DASHBOARD_DIR / "index.html"
        with open(private_path, 'w', encoding='utf-8') as f:
            f.write(html_private)
        print(f"  Created: {private_path}")
        print(f"  Total tasks: {stats_private['total']}")
        
        # Generate public dashboard (exclude private tasks)
        print("\nGenerating public dashboard...")
        stats_public = calculate_stats(tasks, include_private=False)
        html_public = generate_html(tasks, stats_public, is_public=True)
        
        public_path = DASHBOARD_DIR / "public.html"
        with open(public_path, 'w', encoding='utf-8') as f:
            f.write(html_public)
        print(f"  Created: {public_path}")
        print(f"  Total tasks: {stats_public['total']}")
        
        print("\nDashboard generation complete!")
        return 0
        
    except Exception as e:
        print(f"Fatal error: {str(e)}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
