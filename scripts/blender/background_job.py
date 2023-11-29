# This script is an example of how you can run blender from the command line
# (in background mode with no interface) to automate tasks, in this example it
# creates a text object, camera and light, then renders and/or saves it.
# This example also shows how you can parse command line options to scripts.
#
# Example usage for this test.
#  blender --background --factory-startup --python $HOME/background_job.py -- \
#          --text="Hello World" \
#          --render="/tmp/hello" \
#          --save="/tmp/hello.blend"
#
# Notice:
# '--factory-startup' is used to avoid the user default settings from
#                     interfering with automated scene generation.
#
# '--' causes blender to ignore all following arguments so python can use them.
#
# See blender --help for details.


import bpy
from bpy.props import FloatProperty

def read_vars(scene):
    return
    variables = open("vars")
    for line in variables.readlines():
        split = line.split()
        key = split[0]
        val = float(split[1]) if len(split) == 3 else list(map(float, split[1:]))
        scene[key] = val

def example_function(save_path, render_path):
    # Clear existing objects.
    #bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene

    read_vars(scene)

    bpy.context.view_layer.update()

    if save_path:
        bpy.ops.wm.save_as_mainfile(filepath=save_path)

    if render_path:
        render = scene.render
        render.use_file_extension = True
        render.filepath = render_path
        bpy.ops.render.render(write_still=True)

def main():

    import sys       # to get command line args
    import argparse  # to parse options for us and print a nice help message
    # get the args passed to blender after "--", all of which are ignored by
    # blender so scripts may receive their own arguments
    argv = sys.argv

    if "--" not in argv:
        argv = []  # as if no args are passed
    else:
        argv = argv[argv.index("--") + 1:]  # get all args after "--"

    # When --help or no args are given, print this help
    usage_text = (
        "Run blender in background mode with this script:"
        "  blender --background --python " + __file__ + " -- [options]"
    )

    parser = argparse.ArgumentParser(description=usage_text)

    # Example utility, add some text and renders or saves it (with options)
    # Possible types are: string, int, long, choice, float and complex.

    parser.add_argument(
        "-s", "--save", dest="save_path", metavar='FILE',
        help="Save the generated file to the specified path",
    )
    parser.add_argument(
        "-r", "--render", dest="render_path", metavar='FILE',
        help="Render an image to the specified path",
    )

    args = parser.parse_args(argv)  # In this example we won't use the args

    # Run the example function
    example_function(args.save_path, args.render_path)

    print("batch job finished, exiting")


if __name__ == "__main__":
    main()


