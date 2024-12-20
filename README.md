# WIP Developer AI Bash Library

## Introduction and current status

This repository as presently constructed provides:

- A depiction of the duplication of logical functions in the various `bash` scripts employed across the different repositories of [Devloper AI Github Organization](https://github.com/redhat-ai-dev)
- An organization of those bits of `bash` along the following lines:

    - The functional categories or project that serve as `subjects` of the `bash`
    - The `actions` performed on those `subjects`
    - The specific repositories employing which bits of `bash`
  
Conventions used to attempt to provide the information:

- File names start with the name of the repository the `bash` came from
- File names prior to their dot suffix (`.sh` or `.tpl`) attempt to give an indication of the actions performed
- Directory names either are:
  - the subject in the form of the higher level function, product, or concept
  - the action(s) performed against subjects, where those subjects are parent directories
- Symbolic links with the same file name are used when the `bash` in those files addresses multiple concepts, actions, functions, or groups of software

## Current thought on next steps

The "de-duplication" the subesequent reorganization of the `bash` logic seems conceivable along both:

- the categorization around subject type or product lines
- the categorization around actions performed against a given type
- the categorization around actions performed for a given OCP extention

Some of tools available to us for this:

- break up lines of bash into more functions
- minimize as much as reasonable the function to file ratio
- this should allow for use of `source` (or its `.` alias) with `bash` files to import/reuse code, but also avoid bringing in versions of `bash` we may have to replace in odd cases
- parameterize functions when that makes sense (especially when calling function from loops)
- enforce a common set of environment variable names for various concepts (to allow for use of env vars in functions)
- enforce a common set of images 
- use production supported images hosted on `regsitry.redhat.io` whenever possible vs. `appstudio`, `konflux-ui`, or `redhat-ai-dev`
  - which can avoid having to fetch binaries in some cases
  - but when we still do need to fetch (probably to stay on production supported images from `registry.redhat.io`) we should be able to use `wget` instead of `curl`
- leverage `oc` built-ins whenever possible vs. use of YAML piped into `stdin`

Given our `bash` has proliferated from many members of our team, we most likely need a one-off meeting or two to walk through things and decide how we want to reorganize.

Also, a non-trivial amount of suggested cleanup or miscellaneous improvements are suggested with `#TODO` comments.
The walkthrough should consider those as well.

## How will we reuse this repo in our "higher level" repos

### Git submodules

A common means of sharing scripts or configuration files between git repositories, the official doc for them is [here](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

An example pull request where they were introduced by a member of our team is [here](https://github.com/shipwright-io/cli/pull/27) and 
the current state of that shared content is [here](https://github.com/shipwright-io/cli/tree/main/test/e2e/bats)

The [Konflux git-clone image](https://github.com/konflux-ci/git-clone) also leverages them.  This is an image by the way we may want to move off of, but we can dive into that when we process the `#TODO` comments.

The repository with the git submodule can then access the other repository like a subdirectory.

### Next level `source` of bash

`Helm` as a couple of means of pulling in content from other files:

#### The [include function](https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-include-function) 

We in fact leverage in `redhat-ai-dev`.

Consider the conditional include of a Helm artifact named `rhdh.gitops.configure`
- It is defined in a `.tpl` file [here](https://github.com/redhat-ai-dev/ai-rhdh-installer/blob/714aba209602778099132bd3c1c1306872c0df76/chart/templates/openshift-gitops/includes/_configure.tpl#L1)
- And is conditionally included or embedded in a `YAML` file managed by `helm` [here](https://github.com/redhat-ai-dev/ai-rhdh-installer/blob/714aba209602778099132bd3c1c1306872c0df76/chart/templates/configure.yaml#L27)

#### The [Files function](https://helm.sh/docs/chart_template_guide/accessing_files/)

This tweak if you will on include bypasses the need to define templates, and just import entire files.  The higher level `redhat-ai-dev` repository could define `helm` charts which do this, and access files they import via `git submodules` from this repository.

### Sharing Tekton Tasks or Pipelines

To some degree leveraging `helm` post-install hooks that leverage `Jobs` may make sense instead of `pipelines` in some of our cases where we do not need to visualize the status or result of the actions (there are some `#TODO` items around this), but if we get to a point
where sharing `Tasks` or `Pipelines` that house `bash` makes more sense, we of course can leverage [Git Resolvers](https://tekton.dev/docs/pipelines/git-resolver/#simple-git-resolver) that pull `Tasks` or `Pipelines` defined in this repository.
  