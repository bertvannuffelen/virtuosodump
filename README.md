# virtuosodump
A setup of Virtuoso which allows to dump the content of the RDFstore by a HTTP request

Getting the whole content of a virtuoso store is typically done via sql scripts. This
setup configures Virtuoso so that the data is dumped on a predefined location by issuing
a HTTP request.

The advantage of this approach is that the creation of a dump now can be part of any scripting
environment without requiring phyisical access to the server.

Configuration of the scripts
----------------------------

* the names of the dumped dataset files
* the maximum size of dumped dataset files
* the location of the dumped dataset files
* selection of the graphs to be dumped

Configuration of Virtuoso
-------------------------

* upload the configured scripts using isql (or via the conductor isql)
* create a link in the vsp directory to the location of the dumped dataset files
   `` ln -s /data/dumps ``
* configure in the browsing of the dump directory via the conductor:
    * Open the Web Application Server/Virtual Domains & Directories.
    * Click on the New Directory in front of the 0.0.0.0 interface port 80.
    * Select the Type: Filesystem
    * Enter the logical path (part of the URI) fields in the Path and the relative path of the file relative to the vsp/ folder in the Physical path field ( '/dumps/' in the case of the example).
    * Check the box Allow Directory Browsing to enable the directory contents of the course.

* configure in the browsing of the dump directory via the conductor:
    * Open the **Web Application Server/Virtual Domains & Directories**.
    * Click on the **New Directory** in front of the 0.0.0.0 interface port 80.
    * Select the Type: **Filesystem**
    * Enter the logical path (part of the URI) fields in the **Path** (e.g. /gen_dumps) and the relative path of the file relative to the vsp/ folder in the **Physical path** field ( '/dumps/' in the case of the example).
    * Enter the dumpgeneration script in the **Post-processing Function** field. (This script will be executed each time before the respons is sent). for example, ``DB.DBA.dumps_all_graphs``
    * Check the box Allow Directory Browsing to enable the directory contents of the course.


Testing
-------
* upload RDF to a graph which is can be selected for dumping
* test browsing only: http://localhost:8890/dumps
* test generation & browsing: http://localhost:8890/gen_dumps


Improvements
------------
Maybe the gen_dump request should return the list of dataset files, then an download iterator can be build.

