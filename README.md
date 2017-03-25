# Splutnik
## Swift command-line web-server.

A simple web-server, written in Swift 3, that can be run from the commmand-line.

### Configuration

* There are a number of settings at the top of the **Splutnik.swift** file to tune how the server works.
* Use the **.splutnik** file to configure how pages are handled.

### Usage

1. Enable Swift command-line tools.
2. Create a **~/Documents/WebServer** directory. This will contain files to be served. Directories can be nested to any level within this directory and, by default, the request URL is mapped directly to the **WebServer** directory structure. For example, a request for *http://localhost:2108/One/Two/Three/Index.html* will be mapped to the file *~/Documents/WebServer/One/Two/Three/Index.html*. The **WebServer** directory can also contain:
    1. **404.html** - served when the requested page is not found.
    2. **Error.html** - served when an error occurs during the processing of a request.
3. Edit the **.splutnik** file as appropriate. This file should be in the same directory as the **Splutnik.swift** file.
4. Run *Splutnik*:
    1. Open a terminal.
    2. cd to the directory containing **Splutnik.swift**.
    3. Run *./Splutnik.swift*.
