import json
import graphviz
import sys

if len(sys.argv) < 2:
    print("Usage: python script.py <path_to_json_file.json>")
    sys.exit(1)

file_path = sys.argv[1]
try:
    with open(file_path, 'r', encoding='utf-8') as file:
        data = json.load(file)
except FileNotFoundError:
    print(f"Error: The file '{file_path}' was not found.")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Error: Failed to parse JSON file. {e}")
    sys.exit(1)

dot = graphviz.Digraph(name="Etymology_Tree", format="png")
dot.attr(rankdir='TB') 

dot.attr('node', shape='box', style='rounded,filled', fillcolor='#f8f9fa', 
         color='#ced4da', fontname='Helvetica', margin='0.2')

for item in data:
    node_id = str(item['id'])
    
    lang = f'<font color="#6c757d"><i>{item.get("language", "")}</i></font>'
    
    original = item.get("original", "")
    romanized = item.get("romanized", "")
    
    word_line = f'<b>{original}</b>'
    if romanized:
        word_line += f' <font color="#6c757d"><i>| {romanized}</i></font>'
        
    label = f'<<table border="0" cellborder="0" cellpadding="1">'
    label += f'<tr><td>{lang}</td></tr>'
    label += f'<tr><td>{word_line}</td></tr>'
    
    definition = item.get("definition", "")
    if definition:
        label += f'<tr><td>{definition}</td></tr>'
        
    label += '</table>>'
    
    dot.node(node_id, label)

for item in data:
    if "parent_id" in item:
        dot.edge(str(item["parent_id"]), str(item["id"]), color='#adb5bd')

output_file = 'etymology_tree'
dot.render(output_file, view=True)
print(f"Tree generated successfully! Saved as {output_file}.png")
