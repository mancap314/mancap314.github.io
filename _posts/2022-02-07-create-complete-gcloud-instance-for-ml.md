---
layout: post
comments: true
author: Manuel Capel
title: Create a complete instance on Google Cloud for ML
date: 2022-02-07
categories: [machine learning,cloud]
---
If the data volume to process exceeds the capacities of your local computer, it
may be time to switch to a Google Cloud instance with more capacities.

Here you will see how to set up a complete compute instance on Google cloud,
with disk and static IP address attached and finally execute locally a Jupyter
notebook running on this instance.

## Create a new complete instance for ML on Google Cloud
For doing this, follow these steps:

### Prerequisites
The following steps are prerequisites for working with Google Cloud. Execute
them only if you haven't done them already.

1. The `gcloud` CLI has to [be
installed](https://cloud.google.com/sdk/docs/install).

2. You need a Google [Cloud account](https://console.cloud.google.com/).

3. You need to authenticate via your `gcloud` CLI:
```sh
gcloud auth login
```
This will open a browser window for authentication.

4. This instance has to be created within an existing `gcloud` project. Create
   one:
```sh
gcloud projects create my-project --name "My Project"
```
(see [doc](https://cloud.google.com/sdk/gcloud/reference/projects/create))
Now you should see *my-project* when listing your projects through:
```sh
gcloud projects list
```
with its *PROJECT_ID* being `my-project`, its *NAME* `My Project` and its *PROJECT_NUMBER*, an integer id provided by Google Cloud.

5. Get into this project to work within it:
```sh
gcloud config set project my-project
``` 
(Replace `my-project` by the *PROJECT_ID* of your project in this command)

Congratulations, you are all set now :) Let's now create the instance and all
what's required around it:


### Create static IP address
This will make your work easier by always accessing your instance through the
same IP address.
```sh
gcloud compute addresses create my-ipaddress-name \ 
    --region europe-west1
```
Notes:
- Replace `my-ipaddress-name` by any name you want
- The value for *--region* is here `europe-west1`, without the `-b` at the end.


### Give access to Google Cloud Storage
The raw data you want to work on is probably stored on Google Cloud Storage (if
it's not the case skip this step or give access to the resource where the raw
data is stored e.g. BigQuery instead).

To give your instance access to Cloud Storage, you have to give it a
*service-account* containing the *role*s required for accessing the resources
your instance will need.

#### Create *service account*
For creating a *service account* called `my-service-account` (that will be its
ID), enter:
```sh
gcloud iam service-accounts create my-service-account \
    --description="Service Account for My Instance" \
    --display-name="My Service Account"
```

#### Add role to service account
Attach a role to our new *service account* allowing it full permissions to Cloud 
Storage (replace `0123456789` below by your project ID you can see through 
`gcloud projects list`):
```sh
gcloud projects add-iam-policy-binding 123456789 \
    --member="serviceAccount:my-service-account@123456789.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"
```
Now you should see `my-service-account` when entering:
```sh
gcloud iam service-accounts list
```
Note its email, you will need it when creating the instance in the next step.

Note: if you want to give your instance access to to *Cloud Storage* but to
another service, just replace `roles/storage.objectAdmin` in this command by
the *role* corresponding to the access you want to provide to this service` in
this command by the *role* corresponding to the access you want to provide to
this service.


### Create instance
Create a new instance by executing following in the terminal:
```sh
gcloud compute instances create my-instance \
    --machine-type=e2-standard-8 \
    --zone=europe-west1-b \
    --address=my-ipaddress \
    --service-account my-service-account-email
```
This will create an instance with *machine-type* `e2-standard-8` (means: 8
vCPUs, 32GB memory). This should be enough even for demanding ML projects. See
[here](https://cloud.google.com/compute/docs/general-purpose-machines) for an
overview on gcloud *machine-types*. If you want GPUs on your instance, you
should chose an [machine-type including GPU](https://cloud.google.com/compute/docs/gpus#a100-gpus). 
These are more expensive, see their [pricing](https://cloud.google.com/compute/gpus-pricing).

As for the geographic *zone*, you have to chose one fitting you among
[them](https://cloud.google.com/compute/docs/regions-zones). This has also an
influence on the *machine-types* available and the pricing.

Concerning the *--address*, it should be directly the IP address created during
the previous step *and NOT its name*.

For *--service-account*, provide the email of the *service account* created
above.

See
[doc](https://cloud.google.com/sdk/gcloud/reference/compute/instances/create)
for more precisions.


### Add firewall rule
Jupyter notebooks for example open by default on port `8080`. In order to access
to a Jupyter session on your remote instance from your local computer, you have
to enable access to the port `8080` of your remote instance:
```sh
gcloud compute firewall-rules create my-fw-rule-name \
    --allow tcp:8080 \
    --source-tags=my-instance \
    --source-ranges=0.0.0.0/0 \
    --description="Firewall rule for Jupyter on My Instance"
```
(see [doc](https://cloud.google.com/vpc/docs/using-firewalls))
You should now see your new firewall rule `my-fw-rule-name` when entering:
```sh
gcloud compute firewall-rules list
```

### Install disk
If your project deals with a consequent volume of data, you will probably need
more disk space than the 10GB gigabytes provided by default on the instance you
just created. This is the most tedious part, please follow through:

#### Create and attach disk
So for creating e.g. a disk of 300GB named `my-disk` in the same 
zone `europe-west1-b`, execute:
```sh
gcloud compute disks create my-disk \
    --size 300GB \
    --zone europe-west1-b
```

For attaching this disk to `my-instance` created above:
```sh
gcloud compute instances attach-disk my-instance \
    --disk my-disk \
    --zone europe-west1-b
```
(see
[doc](https://cloud.google.com/sdk/gcloud/reference/compute/insoances/attach-disk))


#### Format and mount disk 
Now the new disk is attached to your instance, but this disk still has to be
formatted and mounted in order for your instance to be able to use it.

For this, first connect to the terminal of your remote instance `my-instance`
through ssh:
```sh
gcloud compute ssh my-instance --zone=europe-west1-b
```

Once ou are there, enter:
```sh
sudo lsblk
```
you should see the 300GB vreated and attached above, probably called here
`sdb`.

Then format this disk to `ext4`:
```sh
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
```

Then create a directory called `data-mount` (or whatever you want) where to mount this
disk:
```sh
sudo mkdir -p /data-mount
```

Now mount the disk on this directory:
```sh
sudo mount -o discard,defaults /dev/sdb /data-mount
```

If that's what you want, also give all users write permission on the newly
mounted disk:
```sh
sudo chmod a+w /data-mount
```

Now you should see the disk ready to use when entering:
```sh
df -h
```

#### Enable disk on start
When restarting your instance, you probably want this disk to be available.
For this:
* First, back-up the fstab file:
```sh
sudo cp /etc/fstab /etc/fstab.backup
```

* Second, add the UUID of the new disk to `fstab`:
```sh
echo UUID=`sudo blkid -s UUID -o value /dev/sdb` \
    /data-mount ext4 discard,defaults,noatime,nofail 0 2 \
    | sudo tee -a /etc/fstab
```

* Third, check the UUID of the new disk:
```sh
sudo blkid -s UUID -o value /dev/sdb
```

* Finally, display `fstab` to ckeck that the entry with the UUID of the new disk is there:
```
sudo cat /etc/fstab
```


### Extra steps for Python
Since the compute instance is provided with a bare Linux Debian OS, you have to
install a few additional packages so that the main Python ML libraries can run. For this, keep 
in the remote install terminal and execute:
```sh
sudo apt-get update
sudo apt-get install -y python3-pip git zlib1g-dev \ 
    libffi-dev libblas-dev liblapack-dev libjpeg-dev gfortran
echo -e 'export PATH=$PATH:~/.local/bin' >> ~/.bash_profile
source ~/.bash_profile
```

Then install all the Python libraries you will need, for example:
```sh
pip3 install jupyter sklearn matplotlib
```

### Tunneling Jupyter notebook to your local computer
On your remote instance terminal:
```sh
jupyter-notebook --no-browser --port 8080
```
[Remember: you can access it through `gcloud compute ssh my-instance
--zone=europe-west1-b`]

For *--port* we give `8080` as value, the port open through the firewall rule
added above.

It will provide you a URL to open. Don't open it yet

On your local machine terminal:
```sh
ssh -N -f -L 8080:localhost:8080 my-username@my-instance-ipaddress
```
where `my-username` is your username in the remote instance terminal and
`my-instance-ipaddress` it the static IP address for your instance created
above (you can double-check this IP address through `gcloud compute instances
list` in your terminal).

Now you can open locally the URL provided above when you executed `jupyter-notebook` on
the remote instance

### Starting / Stopping your instance
When you are finished, stop your instance, otherwise you keep on paying for it
(you pay for the time it's running):
```sh
gcloud compute instances stop my-instance
```

When you want to start it again:
```sh
gcloud compute instances start my-instance
```

If you want to work on Jupyter notebook, repeat the steps above in the section
*Tunneling Jupyter notebook to your local computer*


Congratulations, you're ready now to leverage the power of the cloud for your
ML project :))
