---
title: "Install Frappe Framework"
date: 2026-03-23
draft: false
tags: ["frappe", "erpnext"]
categories: ["Tech"]
viewMode: docs
---

[What is Frappe Framework?](https://docs.frappe.io/framework/user/en/basics#what-is-frappe-framework)

Frappe is a full stack, batteries-included, web framework written in Python and Javascript.

It is the framework which powers [ERPNext](https://erpnext.com/). It is pretty generic and can be used to build database driven apps.

> https://docs.frappe.io/framework/user/en/basics



#### So Whats in it

> Doctypes ( similar to form )

> Workflow (enable flow of form from role to role i.e user to authority)

> Client Script (Manages ui Interaction in frappe frontend)

> Server Script (Manages Backend using python - frappe scripts i.e validation, api servering)



### How to work with frappe framework

> Using Docker https://github.com/frappe/frappe_docker

> Using Wsl (linux)



# WSL (linux : Ubuntu)

### Setup wsl windows os 

https://learn.microsoft.com/en-us/windows/wsl/install



1. ```wsl --install --web-download```
2. ```wsl --install``` it will install ubuntu 
3. ```wsl  -d ubuntu``` to login into ubuntu wsl instance (First Login will ask for user-name and password)
4. after login goto home dir ```cd ~```

## setup frappe bench in ubuntu linux (or Wsl Ubuntu)

### Installing Packges

1. ```sudo apt update``` ***update packges***

2. ```sudo apt install git python-is-python3 python3-dev python3-pip redis-server libmariadb-dev mariadb-server mariadb-client pkg-config``` ***install required services***

3. ```sudo apt install xvfb libfontconfig```

4. ```sudo mariadb-secure-installation``` ***it will ask for root password to authorize and ask for new-password for mariadb (if you have not setup this before)***

5. Install Node and Yarn (https://nodejs.org/en/download)

   > Get Node.js® (**V24...lts**) for (**Linux**) Using (**nvm**) With (**Yarn**)

   >```bash
   ># Download and install nvm:
   >curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
   >
   ># in lieu of restarting the shell
   >\. "$HOME/.nvm/nvm.sh"
   >
   ># Download and install Node.js:
   >nvm install 24
   >
   ># Verify the Node.js version:
   >node -v # Should print "v24.11.1".
   >
   ># Download and install Yarn:
   >corepack enable yarn
   >
   ># Verify Yarn version:
   >yarn -v
   >```

​	this will install node and yarn both

### Setup Python Env

1. ```python --version``` ***check python version***
2. ```sudo apt install python3.10-venv``` ***if python version is 3.10***
3. ```python -m venv frappe-env``` ***creating python environment***
4. ```source frappe-env/bin/activate``` ***sourcing the env***

### Bench Setup

1. ```pip install frappe-bench```  ***installing frappe-bench (we will use this to work with frappe-framework)***

2. ```bench init prob```  ***creating bench folder that contains all the configuration and setup of bench / sites /  apps***

3. ```cd prob```  ***directory where from where bench commands can be applied***

4. ```bench new-site frontend``` ***it will asks for super-user and mysql root password***

5. ```bench use frontend``` ***this will set site to frontend***

6. ```bench start```  ***this will start the site***

   > ```bash
   > 
   > …/2025-12-05-test/prob ✗ bench start
   > 15:03:03 system        | redis_queue.1 started (pid=52053)
   > 15:03:03 system        | redis_cache.1 started (pid=52050)
   > ---------------------------------------------------
   > ---------------------------------------------------
   > 15:03:04 web.1         |  * Running on all addresses (0.0.0.0)
   > 15:03:04 web.1         |  * Running on http://127.0.0.1:8000
   > 15:03:04 web.1         |  * Running on http://10.120.10.245:8000
   > 15:03:04 web.1         | Press CTRL+C to quit
   > ----------------------------------------------------
   > ----------------------------------------------------
   > 15:03:11 watch.1       | Watching for changes...
   > ```

   visit http://127.0.0.1:8000

### Basic Bench Commands

#### Run these commands from within the prob directory (you can execute them from a nested subdirectory, as long as one of the parent directories is prob).

---

**```bench init bench_name```**

this commands create bench configuration and folder containing it

---

**```bench new-site sitename```**

creates new site and a site can have multiple selected apps and each site configuration and data does not cross

---

**```bench use sitename```**

to set default site from list of sites 

---

**```bench start```**

to start site , it starts frappe backend and frontend 

---

**```bench build```**

to generate assets of site , apps that frappe will serve

---

**``bench get-app app_name``**

to get frappe official product application i.e. (erpnext, hrms, wiki)  

to get custom application use

**```bench get-app github_repo_url```**

---

**``bench install-app app_name``**

to install app into site , use --site site_name to specify site where app will be installed

---

**```bench new-app customapp```**

to create custom app (where you can define , custom doctype and control apis)

---

**```bench drop-site sitename```**

to remove site  (be cautious it will delete all data related to site)

---

**```bench uninstall-app appname```**

to uninstall app from site , you can use --site sitename

---

**``bench export-fixtures``**

to export configurations and records for doctypes

you have to define what need to export using ``frappe-bench/apps/app_name/module_name/hooks.py``

running command will generate fixtures folder ``frappe-bench/apps/app_name/module_name/fixtures``

fixtures folder will contain json files for each records and configuration

---

**``bench migrate``**

to restore data and configuration that is inside fixtures folder ``frappe-bench/apps/app_name/module_name/fixtures``

---

**``bench set-config config_name config_value``**

to set config like ``bench set-config developer_mode 1`` or ``bench set-config server_script_enabled true``

you can use ``-g`` to set globally

---



### File Folder Structure

---




### Frappe bench

> contains all configurations

```bash
╭─frappe@custom.inxeoz.com ~/frappe-bench
╰─➤  tree -L 1
.
├── apps
├── config
├── env
├── logs
├── patches.txt
├── Procfile
└── sites
```

### apps

> contains all applications
>
> ```
> ╭─frappe@custom.inxeoz.com ~/frappe-bench/apps
> ╰─➤  tree -L 1
> apps
> ├── custom_booking
> └── frappe
> ```
>
> 

### config

> frappe generated config

### env

> python environment that frappe uses

###  logs

> all the logs generated frappe

### patches.text

> all the list of patches that was applied 

### procfile

> Defines how bench runs in production

### sites

> contains sites global configuration and site it self here
>
> ```bash
> 2 directories, 3 files
> ╭─frappe@custom.inxeoz.com ~/frappe-bench/sites
> ╰─➤  tree -L 2
> sites
> ├── apps.json
> ├── apps.txt
> ├── assets
> │   ├── assets.json
> │   ├── assets-rtl.json
> │   ├── css
> │   ├── custom_booking -> /workspace/frappe-bench/apps/custom_booking/custom_booking/public
> │   ├── frappe -> /workspace/frappe-bench/apps/frappe/frappe/public
> │   ├── js
> │   └── locale
> ├── common_site_config.json
> └── custom.inxeoz.com
>  ├── locks
>  ├── logs
>  ├── private
>  ├── public
>  ├── site_config.json
>  └── touched_tables.json
> 
> ```

---

---

### sites/apps.json

> contains application commit hash and github branch if it is from github
>
> ```json
> {
>  "frappe": {
>      "resolution": {
>          "commit_hash": null,
>          "branch": null
>      },
>      "required": [],
>      "idx": 1,
>      "version": "15.87.0"
>  },
>  "custom_app": {
>      "is_repo": true,
>      "resolution": {
>          "commit_hash": "shdskjfhdsfsddsfshdf",
>          "branch": "develop"
>      },
>      "required": [],
>      "idx": 2,
>      "version": "0.0.1"
>  }
> }
> ```
>
> 

### sites/apps.txt

> list of application
>
> ```bash
> ╭─frappe@custom.inxeoz.com ~/frappe-bench/sites
> ╰─➤  cat apps.txt
> frappe
> custom_app                                                                                                                         
> ```



### sites/assets

>contains frontend build of application (symlink to be exact)
>
>```bash
>╭─frappe@custom.inxeoz.com ~/frappe-bench/sites/assets
>╰─➤  tree -L 1
>assets
>├── assets.json
>├── assets-rtl.json
>├── css
>├── custom_booking -> /workspace/frappe-bench/apps/custom_booking/custom_booking/public
>├── frappe -> /workspace/frappe-bench/apps/frappe/frappe/public
>├── js
>└── locale
>```

### sites/common_site_config.json

>contains global information for sites like setting ``bench set-config -g key value`` with ``-g`` updates here
>
>```json
>{
>"background_workers": 1,
>"db_host": "global-db",
>"db_port": 3306,
>"default_site": "custom.inxeoz.com",
>"developer_mode": true,
>"dns_multitenant": true,
>"file_watcher_port": 6787,
>"frappe_user": "frappe",
>"gunicorn_workers": 9,
>"install_apps": [],
>"live_reload": true,
>"rebase_on_pull": false,
>"redis_cache": "redis://fm__custom_inxeoz_com__redis-cache:6379",
>"redis_queue": "redis://fm__custom_inxeoz_com__redis-queue:6379",
>"redis_socketio": "redis://fm__custom_inxeoz_com__redis-cache:6379",
>"restart_supervisor_on_update": true,
>"restart_systemd_on_update": false,
>"serve_default_site": true,
>"shallow_clone": true,
>"socketio_port": 80,
>"use_redis_auth": false,
>"webserver_port": 80
>}
>```

---

---

### sites/custom.inxeoz.com

>contains all information (configuration ) related to site
>
>```
>╭─frappe@custom.inxeoz.com ~/frappe-bench/sites/custom.inxeoz.com
>╰─➤  tree -L 1
>custom.inxeoz.com
>├── locks
>├── logs
>├── private
>├── public
>├── site_config.json
>└── touched_tables.json
>```

### sites/custom.inxeoz.com/locks

### sites/custom.inxeoz.com/logs

### sites/custom.inxeoz.com/private

> contains backup file sql file
>
> ```
> ╭─frappe@custom.inxeoz.com ~/frappe-bench/sites/custom.inxeoz.com/private
> ╰─➤  tree -L 1
> private
> ├── backups
> └── files
> ```

### sites/custom.inxeoz.com/public

### sites/custom.inxeoz.com/site_config.json

>contains configuration details of site like db credentials 
>
>and configs that is set by ``bench set-config key value`` without using ``-g``
>
>```json
>{
>"admin_password": "windwos",
>"db_host": "global-db",
>"db_name": "custom-inxeoz-com",
>"db_password": "windwosBEh",
>"db_port": 3306,
>"db_type": "mariadb",
>"hello": "word"
>}
>```
>
>

### sites/custom.inxeoz.com/touched_tables.json

> contains list of database tables that is created or modified by frappe for site
>
> ```json
> [
>  "tabProperty Setter",
>  "tabSlot Table",
>  "tabWorkflow Action Permitted Role",
>  "tabClient"
> 
> ]
> ```

---

---

### apps/custom_booking

```
╭─frappe@custom.inxeoz.com ~/frappe-bench/apps/custom_booking  ‹develop*›
╰─➤  tree -L 5

custom_booking/
├── custom_booking/
│   ├── config/
│   ├── custom_booking/
│   │   ├── doctype/
│   │   │   ├── api/
│   │   │   ├── approver/
│   │   │   ├── attender/
│   │   │   ├── companion_table/
│   │   │   ├── devoteee/
│   │   │   │   ├── devoteee.json
│   │   │   │   ├── devoteee.js
│   │   │   │   └── devoteee.py
│   │   │   ├── ... many doctypes ...
│   ├── fixtures/
│   ├── hooks.py
│   ├── modules.txt
│   ├── patches.txt
│   ├── public/
│   └── templates/
├── license.txt
├── pyproject.toml
└── README.md

```



> dont confuse yourself by three custom_booking (each has its own meaning)

```
frappe-bench/
└── apps/
    └── custom_booking/          ← The app folder (bench level)
        └── custom_booking/      ← The Python package (custom app name)
            └── custom_booking/  ← The module

```

>doctype folder contains all the doctype, a doctype which created with
>
>Module = custom_booking
>
>Custom? = **Unchecked** (Because Checked would create doctype in database and not map in source code )

```bash
custom_booking/
├── custom_booking/
│   ├── config/
│   ├── custom_booking/
│   │   ├── doctype/				← Doctype folder
│   │   │   ├── api/
│   │   │   ├── approver/
│   │   │   ├── attender/
│   │   │   ├── companion_table/
│   │   │   ├── devoteee/			← Doctype (Devoteee)
│   │   │   │   ├── devoteee.json	← Json file represent the devoteee doctype schema
│   │   │   │   ├── devoteee.js		← js file that controls that devoteee frappe ui
│   │   │   │   └── devoteee.py		← py file that handles backend control like validation
│   │   │   ├── ... many doctypes ...
│   ├── fixtures/					← Fixtures folder (bench migrate)
│   ├── hooks.py					← configs about export and app
│   ├── modules.txt					← list of modules
│   ├── patches.txt
│   ├── public/
│   └── templates/
├── license.txt
├── pyproject.toml
└── README.md

```



### devoteee.json

```json
{
  "actions": [],
  "allow_rename": 1,
  "autoname": "DEV-.########",
  "creation": "2025-01-01 10:00:00.000000",
  "custom": 0,
  "doctype": "DocType",
  "engine": "InnoDB",
  "field_order": [
    "first_name",
    "last_name",
    "mobile_no",
    "email",
    "date_of_birth",
    "address",
    "user",
    "is_active"
  ],
  "fields": [
    {
      "fieldname": "first_name",
      "fieldtype": "Data",
      "label": "First Name",
      "reqd": 1
    },
    {
      "fieldname": "last_name",
      "fieldtype": "Data",
      "label": "Last Name"
    },
    {
      "fieldname": "mobile_no",
      "fieldtype": "Data",
      "label": "Mobile Number",
      "reqd": 1
    },
    {
      "fieldname": "email",
      "fieldtype": "Data",
      "label": "Email",
      "options": "Email"
    },
    {
      "fieldname": "date_of_birth",
      "fieldtype": "Date",
      "label": "Date of Birth"
    },
    {
      "fieldname": "address",
      "fieldtype": "Small Text",
      "label": "Address"
    },
    {
      "fieldname": "user",
      "fieldtype": "Link",
      "label": "Linked User",
      "options": "User"
    },
    {
      "fieldname": "is_active",
      "fieldtype": "Check",
      "label": "Is Active",
      "default": "1"
    }
  ],
  "index_web_pages_for_search": 1,
  "links": [],
  "module": "Custom Booking",
  "name": "Devoteee",
  "owner": "Administrator",
  "permissions": [
    {
      "create": 1,
      "delete": 1,
      "email": 1,
      "export": 1,
      "print": 1,
      "read": 1,
      "report": 1,
      "role": "System Manager",
      "share": 1,
      "write": 1
    }
  ],
  "quick_entry": 1,
  "search_fields": "first_name,last_name,mobile_no",
  "show_name_in_global_search": 1,
  "sort_field": "modified",
  "sort_order": "DESC",
  "title_field": "first_name",
  "track_changes": 1,
  "track_seen": 1
}
```

### devoteee.js

```js
frappe.ui.form.on("Devoteee", {
    refresh(frm) {
        // Add a custom button
        frm.add_custom_button("Get Profile", () => {
            frappe.call({
                method: "custom_booking.custom_booking.doctype.devoteee.devoteee.get_devotee_profile",
                args: { devotee_id: frm.doc.name },
                callback: function(r) {
                    if (r.message) {
                        frappe.msgprint(`
                            <b>Full Name:</b> ${r.message.full_name}<br>
                            <b>Mobile:</b> ${r.message.mobile}<br>
                            <b>Email:</b> ${r.message.email}<br>
                            <b>DOB:</b> ${r.message.dob}<br>
                            <b>Active:</b> ${r.message.is_active}
                        `);
                    }
                }
            });
        });
    },

    // Auto-fill the title when first or last name changes
    first_name(frm) {
        set_title(frm);
    },
    last_name(frm) {
        set_title(frm);
    }
});

function set_title(frm) {
    let title = frm.doc.first_name || "";
    if (frm.doc.last_name) {
        title += " " + frm.doc.last_name;
    }
    frm.set_value("title", title.trim());
}

```

### devoteee.py

```python
import frappe
from frappe.model.document import Document

class Devoteee(Document):

    def before_insert(self):
        """Validate mobile number before creating record."""
        self.validate_mobile()

    def validate(self):
        """Runs on every save."""
        self.validate_mobile()
        self.set_full_name()

    def validate_mobile(self):
        """Ensure mobile number is 10 digits."""
        if self.mobile_no and len(self.mobile_no) != 10:
            frappe.throw("Mobile number must be 10 digits long")

    def set_full_name(self):
        """Auto-set full name for title/representation."""
        self.full_name = f"{self.first_name} {self.last_name or ''}".strip()

@frappe.whitelist()
def get_devotee_profile(devotee_id):
    """
    API Example:
    frappe.call({
        method: "custom_booking.custom_booking.doctype.devoteee.devoteee.get_devotee_profile",
        args: { devotee_id: "DEV-00000001" }
    })
    """
    devotee = frappe.get_doc("Devoteee", devotee_id)
    return {
        "full_name": devotee.full_name,
        "mobile": devotee.mobile_no,
        "email": devotee.email,
        "dob": devotee.date_of_birth,
        "is_active": devotee.is_active,
        "linked_user": devotee.user
    }

```



### hooks.py

```python
app_name = "custom_booking"
app_title = "Custom Booking"
app_publisher = "Your Name / Company"
app_description = "Custom booking application for devotee and VIP slot management"
app_email = "you@example.com"
app_license = "MIT"

# Include Fixtures (Optional)
fixtures = [
    "Client Script",
    "Custom DocPerm"
]

# Document Event Hooks
doc_events = {
    "Devoteee": {
        "validate": "custom_booking.custom_booking.doctype.devoteee.devoteee.validate",
        "before_insert": "custom_booking.custom_booking.doctype.devoteee.devoteee.before_insert"
    }
}

# Whitelisted API Methods (Optional but clean)
override_whitelisted_methods = {
    # Example:
    # "devotee.get_profile": "custom_booking.custom_booking.doctype.devoteee.devoteee.get_devotee_profile"
}

# Home Page (Optional)
# home_page = "login"

# Jinja Options (Optional)
# jinja = {
#     "methods": [],
#     "filters": []
# }

```


Thats it.
