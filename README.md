# VEUNDMINT
VEUNDMINT is a repository that enables users to build their own Online Learning Environments
from Latex files. It will convert latex input to html / css / js output and includes many custom
features such as exercises, tests, glossary, etc. It is easily extendable.

### build status
* branch: develop_software [![build status](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/badges/develop_software/build.svg)](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/commits/develop_software)

## Dependencies
Install these packages using your package manager:

```
libxml2, libxml2-dev, libxslt1-dev, lib32z1, tidy,php-cli, nodejs
```
If the nodejs version provided for your distributio is < 4.x, then see [here](https://nodejs.org/en/download/package-manager/)

## Installation
Clone the repository if not already done and checkout the development branch:
```
git clone git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git VEUNDMINT_DEV
cd VEUNDMINT_DEV
git checkout develop_software
```
The following will install the application in a Python virtual environment. Make sure the command virtualenv is installed:
```
which virtualenv
```
Go to the checkout path and invoke the installation script. This will install all dependencies.
```
make -f tools/makefiles/devinstall
```
To start developing, do:
```
source venv/bin/activate
make -f tools/makefiles/multilang
```
This build everything is in the folder **public**.
To run the server at http://localhost:3000 call:
```
npm run gulp watch &> gulp_output.log &
```

## Manual Installation

Following, you will find installation instructions to get you started. This package is build in **Python3**. To get you started, first clone this repository
```
git clone git@gitlab.tubit.tu-berlin.de:stefan.born/VEUNDMINT_TUB_Brueckenkurs.git VEUNDMINT
cd VEUNDMINT
```
You need permissions, to do so, as long as we are still developing. If you want to participate, send us a request.

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
```
make -f tools/makefiles/multilang
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
