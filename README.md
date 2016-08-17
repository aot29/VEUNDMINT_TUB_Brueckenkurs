

# VEUNDMINT
VEUNDMINT is a repository that enables users to build their own Online Learning Environments
from Latex files. It will convert latex input to html / css / js output and includes many custom
features such as exercises, tests, glossary, etc. It is easily extendable.

### build status
* branch: develop_software [![build status](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/badges/develop_software/build.svg)](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/commits/develop_software)
* branch: develop_gulp [![build status](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/badges/develop_gulp/build.svg)](https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/commits/develop_gulp)

## Installation

Following, you will find installation instructions to get you started. This package is build in **Python3**. To get you started, first clone this repository
```
git clone https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs.git VEUNDMINT
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

#### linux dependencies

```
libxml2, libxml2-dev, libslt1-dev, lib32z1, tidy,
php-cli
```

## Building

## Testing
We use the python module green to run our tests, as it has a nicer user experience and can also run coverage at once. To kick off the tests do
```
green -vvv
```
Tests, divide into different sections, where some will use selenium to test the generated websites. Find the `BASE_URL` setting in settings.py, with that you can adjust the url tests, will be run against. You might also set the environment variable `BASE_URL` to your required url - it will override the settings from settings.py.
