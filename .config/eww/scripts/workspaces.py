#!/usr/bin/python
from subprocess import check_output, Popen, PIPE
from collections import defaultdict
import traceback
try:
    out = check_output(["hyprctl", "clients"]).decode("utf-8") 
    workspaces_out = check_output(["hyprctl", "workspaces"]).decode("utf-8") 
    clients = [line.split('\n') for line in out.strip().split('\n\n')]
    if not clients or not clients[0] or not clients[0][0]:
        clients = []
    max_workspace = max([1]+[int(line.split('\n')[0].split()[2]) for line in workspaces_out.strip().split('\n\n')])

    ps = Popen(('hyprctl', 'monitors'), stdout=PIPE)
    out = check_output(('grep', 'active'), stdin=ps.stdout).decode("utf-8").strip()
    ps.wait()

    classes = defaultdict(set)
    classes["chrome"] = {"chrome"}
    classes["files"] = {"nautilus", "dolphin"}
    classes["inkscape"] = {"inkscape"}
    classes["gimp"] = {"gimp"}
    classes["term"] = {"kitty", "alacritty"}
    classes["blank"] = {"rofi", "wofi"}
    classes["zip"] = {"file-roller"}
    classes["image"] = {"thumb"}
    classes["volume"] = {"pavu", "pulse"}
    classes["office"] = {"desktopeditors", "libreoffice"}
    classes["text"] = {"gedit"}
    classes["code"] = {"pycharm","jetbrains", "code"}
    classes["spotify"] = {"spotify"}
    classes["discord"] = {"discord"}
    classes["blender"] = {"blender"}
    classes["settings"] = {"settings", "conf", "font", "eww"}
    classes["fl"] = {"fl"}
    classes["vlc"] = {"vlc"}
    classes["firefox"] = {"firefox"}
    classes["zoom"] = {"zoom"}

    workspaces = defaultdict(set)

    active_workspaces = set()
    for line in out.split('\n'):
        active_workspaces.add(int(line.split()[2]))

    def get_labels(icons, active):
        return "".join(f'(label :text " " :class "wlabel" :style "background-image: url(\'images/{icon if not active else icon+"-alt"}.svg\');")' for icon in icons)


    def get_button(workspace):
        u = "used"
        icons = []
        if workspace not in workspaces:
            u = "unused"
        else:
            icons = sorted(workspaces[workspace])
        a = "active" if workspace in active_workspaces else "inactive"
        return f'(button :class "{a} {u} workspace" :onclick "hyprctl dispatch workspace {workspace} " (box :orientation "h" :hexpand false :space-evenly false {get_labels(icons, workspace in active_workspaces)}))'

    for client in clients:
        workspace = int(client[5].split()[1])
        if workspace == -1: continue
        if len(client[8].split()) < 2: continue
        max_workspace = max(max_workspace, workspace)
        name = client[8].split()[1].lower()
        title = client[9].split()[1].lower()
        icon = None
        for key in classes:
            for word in classes[key]:
                if word in name:
                    if key == "term":
                        if "ranger" in title:
                            icon = "files"
                            break
                    icon = key
                    break
            if icon:
                break
        else:
            icon = "other"
        if icon != "blank":
            workspaces[workspace].add(icon)
    out = []
    for w in range(1, max_workspace+1):
        out.append(get_button(w))
    front = '(box :orientation "h" :space-evenly false'
    end = " )"
    print(front+''.join(out)+end)
except Exception as e:
    f = open("/home/taylor/eww_error_log.txt", "w")
    f.write(str(e)+'\n\n')
    f.write(traceback.format_exc())
    f.write("\n\n")
    for client in clients:
        f.write(str(client))
        f.write('\n')
        f.write(str(client[8]))
        f.write('\n')
    f.close()

