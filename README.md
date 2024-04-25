# Docker

We're going to use our PDE solvers through a tool called docker.
What docker does is let you pretend, for the duration of one terminal session, like you're running a different operating system.
If you like analogies, you can think of this like logging in remotely to another machine running Linux that someone else (me) has already prepared with the software you'll need on it.
This other machine isn't actually remote but rather running in an isolated environment (a container) on your system.

I'll walk through how we do this step-by-step.

### Fetch a docker image

I've prepare an *image* or blueprint for what the virtual machine will look like and uploaded it to the internet.
First, run the following command at a terminal:

```shell
docker images
```

You should see just this, indicating that you don't have any images:

```
REPOSITORY                           TAG        IMAGE ID       CREATED         SIZE
```

Next we'll pull an image from the internet by running this command at a terminal:

```shell
docker pull icepack/uw-ess524:2024-04-25
```

Here `icepack` is the name of my user account, `uw-ess524` is the name of the image, and `2024-04-25` is the version string.
This version string can be lots of things; I've made it with the date that I built the image.
At some point during the class I may ask you to fetch a fresh image.

You should see a bunch of terminal output showing that it's downloading and extracting things.
If you run `docker images` at a terminal again, you should see something like the following:

```
REPOSITORY                           TAG          IMAGE ID       CREATED          SIZE
icepack/uw-ess524                    2024-04-25   6ec26996ea83   34 seconds ago   9.31GB
```


### Run a docker image

Now that you have the image, we can spin up a virtual machine or container from that image.
Enter the command below at a terminal window:

```shell
docker run --interactive --tty icepack/uw-ess524:2024-04-25
```

The *run* part of the command says that we want to start up a container or virtual machine based on the image named at the end of the command.
The `--interactive` and `--tty` arguments say that we want to be able to type commands interactively at a terminal session running inside this virtual machine.
We have to specify these arguments because very often people use containers to run programs which they don't want to interact with at all in the background.

After you enter the docker run command, you should see your terminal prompt change to something like this:

```
firedrake@a760c6148018:~$ 
```

indicating that inside this terminal session, it looks like you're working on a different machine.
From here, you could try opening an `ipython` interpreter and doing `import firedrake`, which ought to work.
This docker image has Firedrake pre-installed.

You can do any of the usual linux shell commands from this terminal.
For example, you'll probably need to do a `git clone` command inside the container to, say, fetch the class notebooks.
Your user account inside the container has super-user privileges, so you can use the package manager (`apt-get`) to install new software if you want.
The container cannot talk to the rest of your system, so there's no risk at this point of breaking anything.

When you type `exit`, the container will stop and you'll be working on your host system once again.
If you do `docker run ...` again, the resulting container is totally fresh -- there is no memory of your previous session.

### Sync a directory

We're going to want to move files back and forth between the container and your host system -- notebooks, figures, simulation output, whatever.
We have to be very specific about how and which files to share with a container because security.
To continue the analogy that using containers is a little bit like logging into someone else's server remotely, if you want to share files with a system that you've SSHed into, you need a special command to do that: `scp`.

What we'll do next is sync a directory on our host system with a directory in the container.
If we put files in this directory from our host system, they'll appear in the container, and if we put files into it from inside the container, we can see them on our host system too.
I usually make a fresh, empty directory just for syncing files with containers.
Suppose that the directory I want to sync is called `files-to-sync` and it lives in my home directory, and I want to sync it with a directory of the same name in the home directory of the container.
We sync files by passing an extra argument `--volume` to the docker run command:

```shell
docker run \
    --interactive \
    --tty \
    --volume /home/daniel/files-to-sync:/home/firedrake/files-to-sync \
    danshapero/uw-ess524:2024-04-25
```

A few things to note here.
First, the directory name on the host system comes first, then a colon, then the directory name in the container.
Second, **you always have to put in the absolute path to the folders you want to sync.**
So if, for example, I were in my home directory when I executed this command but I used `files-to-sync` as the first argument, then I'd get an error.
You must likewise use an absolute path on the container.
To do that, you need to know the username in the container; in this case it's Firedrake, but if you downloaded a random Docker image and weren't sure, you could start up a container and then do `whoami` to find out.

A typical workflow for this class would be to start up a container, make a jupyter notebook inside it (more on that soon), make some edits to the notebook, then move the notebook onto your host system so that you can send it to me.
If you're using docker for real work, there are loads of other ways you might use this.
You could run a simulation inside a container, then save the results to disk and move them to your host system for further analysis or postprocessing later.
If you're working with, say, large remote sensing datasets that you already have downloaded to your machine, then using `--volume` is a good way to make them accessible inside the container without having to download them again each time inside the container.

### Jupyter

There's one final thing to do before we're really cooking.
When you start up a jupyter lab server, you're really creating a web server on your computer that you then connect to through your browser.
That web server is listening for connections on a certain port number.
Ordinarily, this process would be completely seamless and you'd never notice this detail.
When we're working in a container, however, we have to explicitly sync ports with the host system because security again.
To do this, we pass the argument `--publish` to docker run:

```shell
docker run \
    --interactive \
    --tty \
    --publish 9000:9000 \
    --volume /home/daniel/files-to-sync:/home/firedrake/files-to-sync \
    danshapero/uw-ess524:2024-04-25
```

You don't have to use port 9000, it could be almost anything you want.

Next we need to start up the jupyter server.
When you execute `jupyter lab` on your host system, a new browser tab gets opened automatically which connects to the jupyter server.
We don't have that convenience anymore, so we have to do things a little bit more explicitly.
First, the command to execute from inside the container is:

```shell
jupyter lab --no-browser --ip 0.0.0.0 --port=9000
```

The port number that you enter here has to be the same as the port number that you entered when you did the docker run command.
The `--no-browser` argument tells jupyter not to try to open a web browser, which it won't be able to do successfully.
I have no idea why we have to specify the IP address, it just doesn't work without it.

Now how do we connect to the jupyter server?
The last command should have spat out a bunch of terminal output.
Here's a sample:

```
[I 2024-04-29 01:01:43.732 ServerApp] jupyter_lsp | extension was successfully linked.
[I 2024-04-29 01:01:43.738 ServerApp] jupyter_server_terminals | extension was successfully linked.
[I 2024-04-29 01:01:43.746 ServerApp] jupyterlab | extension was successfully linked.
[I 2024-04-29 01:01:43.752 ServerApp] notebook | extension was successfully linked.
[I 2024-04-29 01:01:43.754 ServerApp] Writing Jupyter server cookie secret to /home/firedrake/.local/share/jupyter/runtime/jupyter_cookie_secret
[I 2024-04-29 01:01:44.326 ServerApp] notebook_shim | extension was successfully linked.
[I 2024-04-29 01:01:44.346 ServerApp] notebook_shim | extension was successfully loaded.
[I 2024-04-29 01:01:44.349 ServerApp] jupyter_lsp | extension was successfully loaded.
[I 2024-04-29 01:01:44.350 ServerApp] jupyter_server_terminals | extension was successfully loaded.
[I 2024-04-29 01:01:44.353 LabApp] JupyterLab extension loaded from /home/firedrake/firedrake/lib/python3.10/site-packages/jupyterlab
[I 2024-04-29 01:01:44.353 LabApp] JupyterLab application directory is /home/firedrake/firedrake/share/jupyter/lab
[I 2024-04-29 01:01:44.353 LabApp] Extension Manager is 'pypi'.
[I 2024-04-29 01:01:44.413 ServerApp] jupyterlab | extension was successfully loaded.
[I 2024-04-29 01:01:44.418 ServerApp] notebook | extension was successfully loaded.
[I 2024-04-29 01:01:44.418 ServerApp] Serving notebooks from local directory: /home/firedrake
[I 2024-04-29 01:01:44.418 ServerApp] Jupyter Server 2.14.0 is running at:
[I 2024-04-29 01:01:44.418 ServerApp] http://f6ce95637df6:9000/lab?token=2d9bb87712aac996ba98c3e8c2783a393601895e7c8741c9
[I 2024-04-29 01:01:44.418 ServerApp]     http://127.0.0.1:9000/lab?token=2d9bb87712aac996ba98c3e8c2783a393601895e7c8741c9
[I 2024-04-29 01:01:44.419 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 2024-04-29 01:01:44.422 ServerApp] 
    
    To access the server, open this file in a browser:
        file:///home/firedrake/.local/share/jupyter/runtime/jpserver-13-open.html
    Or copy and paste one of these URLs:
        http://f6ce95637df6:9000/lab?token=2d9bb87712aac996ba98c3e8c2783a393601895e7c8741c9
        http://127.0.0.1:9000/lab?token=2d9bb87712aac996ba98c3e8c2783a393601895e7c8741c9
[I 2024-04-29 01:01:44.449 ServerApp] Skipped non-installed server(s): bash-language-server, dockerfile-language-server-nodejs, javascript-typescript-langserver, jedi-language-server, julia-language-server, pyright, python-language-server, python-lsp-server, r-languageserver, sql-language-server, texlab, typescript-language-server, unified-language-server, vscode-css-languageserver-bin, vscode-html-languageserver-bin, vscode-json-languageserver-bin, yaml-language-server
```

You should see one file path and two different web addresses.
You're looking for the web address that starts with `http://127.0.0.1/...` with a bunch of random characters after the IP address.
Copy/paste this web address into your browser window and you should see a jupyter lab server start up.
In the terminal output I copy/pasted above, that address is:

```
http://127.0.0.1:9000/lab?token=2d9bb87712aac996ba98c3e8c2783a393601895e7c8741c9
```

but the token is randomly-generated and will be different when you run this.
The other address (`http://f6ce95637df6...`) doesn't seem to work, I have no idea why.


# All together

The full run command, which you'll be using the most, is

```shell
docker run \
    --interactive \
    --tty \
    --publish 9000:9000 \
    --volume <absolute path to sync folder on host>:/home/firedrake/<name of folder to sync> \
    danshapero/uw-ess524:2024-04-25
```

You could create a notebook from scratch in a moment, but if you're going to work off of one of the class demo notebooks, you'll need to fetch them into the container:

```shell
git clone https://github.com/uw-ess524/ess524-spring-2024
```

Finally, you'll want to start up a jupyter lab server:

```shell
jupyter lab --no-browser --ip 0.0.0.0 --port=9000
```

and finally copy/paste the web address starting with `http://127.0.0.1/...` into a browser window.
