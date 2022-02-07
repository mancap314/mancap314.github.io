---
layout: post
comments: true
author: Manuel Capel
title: Create a Python library
date: 2021-01-14
categories: [programming]
---
Creating a Python package isn’t typically something a developer does routinely, so when it happens, you may end up losing time and nerves in small details you forgot. This article will show you how to make your project pip install-able.

Here is a (hopefully) simple gentle guide easy to follow for proceeding. Just take it as a small recipe when you need to cook your Python package once in a while.

Let’s go step by step:

## Prerequisite

You have first to install the packages [setuptools](https://pypi.org/project/setuptools/), [wheel](https://pypi.org/project/wheel/), and [twine](https://pypi.org/project/twine/):

```sh
pip install setuptools wheel twine
```

## Project structure

The first-level folder structure of your project (from now on called *mypackage*) should look like this:

```sh
|___ LICENCE
|___ mypackage/
|___ README.md
|___ requirements.txt
|___ setup.py
|___ tests/
```

Let’s quickly review what’s in there:

* **LICENCE**: The license for your project. If it’s open-source, an [MIT](https://en.wikipedia.org/wiki/MIT_License) license is probably good to go. See [more possible licenses](https://choosealicense.com/).
* **mypackage/**: Folder where your actual will leave. **Note**: this folder and every subfolder should contain an `__init__.py` file (even empty) to be accessible in mypackage.
* **README.md**: Long description of your project. It will also appear on the front page of your Github repo. Has to be written with [Markdown syntax](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
* **requirements.txt**: Contains the description of the packages *mypackage* depends on. Each line of this file is of the form *packagename[==version]*. You can generate it directly through `pip freeze > requirements.txt` in the terminal if you are using a virtual environment, which is highly recommended btw. See more [there](https://blog.usejournal.com/why-and-how-to-make-a-requirements-txt-f329c685181e).
* **setup.py**: This one is a bit more complex. It should look like this:

```python
import setuptools

with open('README.md', 'r', encoding='utf-8') as fh:
    long_description = fh.read()

setuptools.setup(
    name='mypackage',
    version='0.0.1',
    author='My Name',
    author_email='my.name@somemail.xyz',
    description='My super duper Python package',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/myusername/mypackage',
    packages=setuptools.find_packages(),
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
    install_requires=[
        'somepackage>=1.1.0',
    ]
)
```

You can take this and replace the values with the ones corresponding to you resp. your project. **Note**: specifying your project dependencies in requirements.txt is not enough to make them get automatically installed along with your package, you have to repeat them in `install_requires`.

* **tests/**: contains the (unit) tests for your package. It can’t harm to have some tests, to say the least.

## Generate Package

This step is fairly easy. Go to the root folder of mypackage in the terminal and execute:

```sh
python setup.py sdist bdist_wheel
```

Now you should see one new file: `mypackage.egg-info` and two new folders: `build` and `dist` in your project’s root directory.
Test locally

For this, still, on your terminal at *mypackage*’s root directory, run:

```sh
pip install mypackage/
```

Now you can create a script importing your package and test if it works as expected.

## Publish your package

Ready to go, happy with the result? Then publish your new package and make it available to the world!

First, you have to create an account on [PiPy](https://pypi.org/). Then, at the same place in your terminal, run:

```sh
twine upload dist/*
```

A prompt will appear asking you for your user name and password on PiPy. Then your package gets uploaded and… that’s it! Now anyone in the world can use your package!

Well, that’s hopefully not the end of the story. Your package may live, evolve and you might want to:

## Update your package

For this, first, bump *mypackage*’s version in *setup.py*. Then re-run `python setup.py sdist bdist_wheel` and `twine upload dist/*`. Your new version of mypackage is now also available to the world!

That was it. As an example you can look at [matrad](https://github.com/mancap314/matrad), a library I recently created for interfacing the [Binance API](https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md) in Python (could be the subject of another story…).

Hope this helps and thanks for reading!
