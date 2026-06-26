# Response style

As terse as possible. All technical substance should stay. Get rid of fluff.
Don't say things like: "Sure! I'd be happy to help you with that.", "Of course! Here's how you can do that.", "Sorry for the confusion", etc. Just get to the point.
End responses by asking if you should do a suggested next step, or if you have any other questions.
If you are unsure about what to do, ask for clarification. Don't make unreasonable assumptions, but feel free to make reasonable ones if it helps you move forward. If you make an assumption, state it explicitly.

# Code style

Avoid adding comments as much as possible. Comments should be added when something is non-obvious. They should explain the WHY not the WHAT. However, do not remove other people's comments if they are not related to the current change, even if you think they are unnecessary. If you find comments that are no longer relevant, or do not fit the non-obvious criterion but are related to the current change, feel free to remove them as needed.
Avoid duplicating code. If the same code needs to exist in multiple places, a reasonable attempt should be made to refactor it into a shared function or module.
Avoid keeping code around for "backwards compatibility". If something needs to truly be backwards compatible, I will explicitly tell you. Otherwise, feel free to remove or refactor old code as needed.
Avoid 1-liner functions that just call another function. If a function doesn't do anything other than call another function, consider just calling the second function directly.
Similarly, avoid assigning function calls to variables if the variable is used only once. Just call the function directly where it's needed. However, if assigning to a variable significantly improves readability, it's fine to do so.
In all cases, prioritize concise, clean code.
In tests, never use a timeout directly. For instance, in a javascript test, you would never do something like `await new Promise((resolve) => setTimeout(resolve, 50));` to wait for something to happen. Instead, use a proper waiting mechanism that waits for a specific condition to be true, or for a specific event to happen. This makes tests more reliable and less flaky.

# Execution style

If a follow-up modifies only one attribute of a multi-attribute request, treat it as replacing only that attribute. Keep the other requested attributes intact unless explicitly cancelled.
If a file changes between edits, there is a good chance that I manually modified the file. Do not remove those changes unless they are causing problems, and then check with me first.

# Local code references

convo-ai/conversational-ai: ~/convo-ai/
afm/atlassian-frontend-monorepo: ~/atlassian/afm/master/
confluence backend/monolith: ~/confluence/

Other code may be found with bitbucket.

# Tools

`twg`: A command line interface to the Atlassian Teamwork Graph and Cloud services. TWG is Atlassian's enterprise knowledge & context graph that continuously maps people, content, activities, and relationships across many work tools (Jira, Confluence, Google Drive, Slack, GitHub, Salesforce, etc.)
Usage: /Users/jtaylor11/.local/bin/twg [options] [command]

`agent-browser`: Useful for frontend work, especially reproducing bugs and validating fixes. 
agent-browser - fast browser automation CLI for AI agents

Usage: agent-browser <command> [args] [options]
Can be run in --headed mode. 
To discover available commands and usage patterns, run:
`agent-browser skills get core --full`

Skills ship with the CLI (always version-matched) and include workflow patterns, ref/selector usage, and copy-paste examples. Prefer this over guessing commands from flag docs alone. 
skills [list]                List available skills
skills get core              Core usage guide (overview + common patterns)
skills get core --full       Include full command reference and templates
skills get <name>            Load a specialized skill (electron, slack, ...)
skills path [name]           Print skill directory path

# Other context

My name (the user) is Josh Taylor. When you see people refer to "Josh" in messages, you know they will be talking about me. You should refer to me as "you" in your responses, and refer to yourself as "I".

# Reflect

After a session, reflect on how it went. Think about how we could have reached resolution state faster, with less back-and-forth. Suggest things that I could do differently, and suggest improvements to the above guidelines. These guidelines can be found in ~/AGENTS.md.

# Repo specific guidelines

When working in convo-ai

- Do not create feature gates/experiments in large files that define many other gates/experiments. Instead, put the new gate/experiment as close as possible to the code that uses it. Create a new file if necessary.
- When using a gate, prefer the syntax rolloutService.controlledByFullContext(EXPERIMENT).replacing { old behavior }.with { new behavior }.value over boolean helper methods. When using an experiment, use .with/withSuspend

When working in afm

- Upon user request, use agent-browser to manually test, reproduce bugs, and validate fixes in the dev server environment.
- The dev server can be started with the command `PORT=<unused_port_1> ATLASPACK_INCREMENTAL_PORT=<unused_port_2> afm run start --atlaspack-incremental 2>&1 | tee <current_working_directory>/tmp.log`. It is important to tee to exaclty `<current_working_directory>/tmp.log`, so that I will be able to discover the log file and check it for errors if something goes wrong.
- Auth cookies for hello (prod) will be defined in .env for tenant.session.token and atlassian.xsrf.token. You will need these when first connecting to <unused_port_1>. Feel free to read the .env file directly, these are ephemeral tokens that will likely need to be updated frequently so they are not a security risk.
- On first connection, you will see a form to select a tenant and provide cookies. Select hello and input the cookies from .env.
- Once the form is submitted, you should be able to navigate to localhost:<unused_port_1>/<any_production_path> and see the production version of the page, but with your local code changes reflected.
- Feature gates and experiments can be enabled/disabled by clicking the flag icon (button containing the span with aria-label="Statsig overrides")

