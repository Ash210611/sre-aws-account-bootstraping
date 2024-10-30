#!/usr/bin/env python
from setuptools import setup, find_packages

setup(
    name='helper_tools',
    version='0.1.0',
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        'Click',
    ],
    entry_points={
        'console_scripts': [
            'nlbprocessing = helpertools.src.nlbprocessing:cli',
        ],
    },
)
