# VEUNDMINT
VEUNDMINT is a repository that enables users to build their own Online Learning Environments
from Latex files. It will convert latex input to html / css / js output and includes many custom
features such as exercises, tests, glossary, etc.

### build status
* branch: dev_TUB_software [![build status](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/badges/dev_TUB_software/build.svg)](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/commits/dev_TUB_software)

## Dependencies
Install these packages using your package manager:

```
libxml2, libxml2-dev, libxslt1-dev, lib32z1, nodejs, doxygen
```
If the nodejs version provided for your distribution is < 4.x, then see [here](https://nodejs.org/en/download/package-manager/)

This page documents how to set up an environment to work on existing courses or build a new one. There are two ways you can work on a course. *Content developers* write texts and exercises, *Software developers* work on the conversion software. Choose the documentation which best suits your needs. If you intend to work on both, then choose *Software developers*.

# Content developers
## 1. The first time around, 
you will need to clone the content development branch and install it:
```
git clone --single-branch -b dev_VBKM_content git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git VEUNDMINT_VBKM_CONTENT
cd VEUNDMINT_VBKM_CONTENT
make install
```
The LaTeX files can now be found in the **directory "content"**. 

## 2. To edit the content, 
you can now open a .tex file using Texmaker, and you should be able to build a PDF with it. 

## 3. To update, 
the content and the software to the latest version, use:
```
make update
```

# Software developers

## 1. The first time around, 
you will need to clone the  development branch:
```
git clone --single-branch -b dev_TUB_software git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git VEUNDMINT_DEV
cd  VEUNDMINT_DEV
```

## 2. Install a development environment 
and **choose the course you want to work with** by passing the name of the content branch. 

To install the maths course, do:
```
make install  branch=dev_VBKM_content
```
Alternatively, to install the physics course, do:
```
make install branch=dev_Physik_content
```
 
## 3. Working on the code and building the course
Start the **virtual environment** by doing
```
source venv/bin/activate
```
Make changes, then build the course. To build the **maths course**, do:
```
make all
```
Alternatively, to build the **physics course**, do: 
```
make all course=PhysikBK
```
## 4. Testing
You can now start the webserver and see the result in a browser by calling (preferably in another console):
```
npm run gulp watch
```
To run the **test suite**, make sure the webserver is running, then call
```
make test
```
## 5. Updating
**To update** the source code and the content submodules, use
```
make update
```

##See
* https://git-scm.com/book/en/v2/Git-Tools-Submodules
* http://stackoverflow.com/questions/1777854/git-submodules-specify-a-branch-tag

# If you want to participate
You need permissions to do so, as long as the code has not been published on a public repo. If you want to participate, send us a request.

Familiarize yourself with thes system by reading [How does the conversion LaTeX -> HTML work?](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/How%20does%20the%20conversion%20latex%20-%3E%20html%20work)
and [Expanding the system using the Python API](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/Python%20API%20Documentation).

# Manual installation instructions
If the above instructions don't work as expected on your system, please proceed as follows:

Instructions to install the system manually. This package is build in **Python3**. First clone this repository
```
git clone --single-branch -b dev_TUB_software git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git VEUNDMINT_DEV
cd VEUNDMINT_DEV
```
and **choose the course you want to work with** by passing the name of the content branch. 

To install the maths course, do:
```
make install  branch=dev_VBKM_content
```
Alternatively, to install the physics course, do:
```
make install branch=dev_Physik_content
```

### Virtual Environment

This step is optional but highly recommended. To setup a virtual environment in python 3, go to the root directory of the repository and run:
```
virtualenv -p python3 venv
```
All python packages can now be installed into the local virtual environment located at `venv/`.
#### Activate the Virtual Environment
```
source venv/bin/activate
```
#### Deactivate the Virtual Environment
```
deactivate
```

### Install (python) dependencies

In order to use the VEUNDMINT converter, you need to have python3 installed. To automagically install all required python modules, just run (in the root directory)
```
pip install -r requirements.txt
```

## Building
Recommended: Install node package manager (npm) via the [nvm bash script](https://github.com/creationix/nvm). For alternatives and detailed installation instructions, see our [Wiki](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/Code-refactoring)
### install dependencies for web version
```
npm install
bower install
(or npm run bower_install if using a virtual Python environment)

```
### start make script that will kick off the converter and run gulp afterwards
Make changes, then build the course. To build the **maths course**, do:
```
make all
```
Alternatively, to build the **physics course**, do: 
```
make all course=PhysikBK
```
### run development server
```
gulp watch
(or npm run gulp watch if using a virtual Python environment)
```


## Testing
We use the python module green to run our tests, as it has a nicer user experience and can also run coverage at once. To kick off the tests do
```
green -vvv
```
Tests, divide into different sections, where some will use selenium to test the generated websites. Find the `BASE_URL` setting in settings.py, with that you can adjust the url tests, will be run against. You might also set the environment variable `BASE_URL` to your required url - it will override the settings from settings.py.

## Logging
### Frontend / javascript log
We use the javascript package [loglevel](https://github.com/pimterry/loglevel) for logging. Default loglevel is set to `error`, which will only display errors in the console. For debugging, do
```javascript
log.setLevel('debug')
```
