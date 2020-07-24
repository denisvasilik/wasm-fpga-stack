import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

__tag__ = ""
__build__ = 0
__commit__ = "00000000"
__version__ = "{}{}".format(__tag__, __build__)

setuptools.setup(
    name="wasm-fpga-stack",
    version=__version__,
    author="Denis Vasilìk",
    author_email="contact@denisvasilik.com",
    url="https://github.com/denisvasilik/wasm-fpga-stack/",
    project_urls={
        "Bug Tracker": "https://github.com/denisvasilik/wasm-fpga/",
        "Documentation": "https://wasm-fpga.readthedocs.io/en/latest/",
        "Source Code": "https://github.com/denisvasilik/wasm-fpga-stack/",
    },
    description="WebAssembly FPGA Stack",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3.6",
        "Operating System :: OS Independent",
    ],
    dependency_links=[],
    package_dir={},
    package_data={},
    data_files=[("", ["CHANGELOG.md"])],
    setup_requires=[],
    install_requires=[],
    entry_points={},
)
