# Chapter 5 — User Manual

## 5.1 Installation Guide

This guide explains how to install and run the **SprintSight** system on a clean machine. The
application is fully containerized with Docker, so once the prerequisites below are installed,
the entire system — frontend, backend, database, and AI prediction service — is built and
started with a single command. This guide is also provided as a `README` file on the delivery CD.

---

### 5.1.1 System Architecture Overview

SprintSight is composed of four independent services that run as Docker containers on a single
private network. The user only ever interacts with the **frontend** over HTTPS; all other services
communicate internally and are not exposed directly to the user.

| Service | Container name | Technology | Image / Base | Port (host → container) | Reachable by user? |
|---|---|---|---|---|---|
| Frontend (Web UI) | `sprintsight-frontend` | React build served by Nginx | `nginx:1.27-alpine` | `80 → 80`, `443 → 443` | **Yes** (HTTPS) |
| Backend (REST API) | `sprintsight-backend` | Spring Boot (Java 21) | `eclipse-temurin:21-jre` | internal only (`8080`) | No (via frontend proxy) |
| AI Prediction Service | `sprintsight-prediction` | Python 3.13 / FastAPI | `python:3.13-slim` | internal only (`8000`) | No |
| Database | `sprintsight-db` | PostgreSQL 17 | `postgres:17-alpine` | `5432 → 5432` | No (DB tooling only) |

The frontend's Nginx server redirects all HTTP traffic to HTTPS and forwards every request under
`/api/` to the backend container. The backend reads and writes to the PostgreSQL database and calls
the prediction service for AI-based predictions. Startup order and readiness are managed
automatically by Docker health checks, so the backend will not start until both the database and the
prediction service report healthy.

---

### 5.1.2 System Requirements

**Operating system**

- A 64-bit **Linux** distribution (e.g. Ubuntu 22.04 LTS or later).

**Hardware (minimum recommended for the demo machine)**

- CPU: 4 cores.
- RAM: **8 GB or more.** The prediction service alone reserves 2 GB and may use up to 3 GB while
  loading its language model; the database and backend require additional memory on top of that.
- Free disk space: **at least 10 GB**, to hold the Docker images and the AI model that is downloaded
  during the build.

**Network**

- An **internet connection is required during the first build** to download the base images, the
  backend's Maven dependencies, the frontend's npm packages, and the AI model (`BERTOverflow`)
  together with the NLTK data set.
- An **internet connection is also required at run time.** The backend uploads and retrieves images
  through the external Cloudinary service, which the machine must be able to reach while the
  application is in use. (The AI model itself runs locally and needs no internet once the build is
  complete.)

---

### 5.1.3 Required Third-Party Tools

The following tools must be installed on the host machine before installation. Versions shown are the
versions the system was tested with; newer compatible versions are acceptable.

| Tool | Purpose | Suggested install command (Ubuntu/Debian) |
|---|---|---|
| **Docker Engine** | Builds and runs the containers | `sudo apt-get install docker-ce` (see Docker's official Linux install guide) |
| **Docker Compose v2** | Orchestrates the four services together | Included with Docker Engine as the `docker compose` plugin |
| **Git** *(optional)* | Obtains the source if not installed from the CD | `sudo apt-get install git` |

---

### 5.1.4 Obtaining the Project Files

The system is split across four Git repositories: one **deployment** repository that holds the
orchestration files, and three **service** repositories (backend, frontend, and prediction). The
service repositories must be cloned **inside** the deployment repository, each into a folder with an
exact, specific name, because the orchestration file builds each service from those folder paths.

1. Clone the deployment repository and enter it. This folder becomes the project root for every
   command in this guide:
   ```bash
   git clone https://github.com/AbdEl-Rahman21/SprintSight_Deployment sprintsight
   cd sprintsight
   ```

2. From inside the deployment repository, clone the three service repositories, giving each the exact
   target folder name shown as the final argument of each command:
   ```bash
   git clone https://github.com/animus212/SprintSight_Back backend
   git clone https://github.com/YoussefEsam23/sprint-sight frontend
   git clone https://github.com/YousefMohamed021/Sprint-Sight-AI-API prediction
   ```

> **The folder names matter.** They must be exactly `backend`, `frontend`, and `prediction`. If you run
> `git clone` without specifying the target name, Git creates folders named after the repositories
> instead, and the build in step 5.1.8 will fail.

After cloning, the deployment repository (the project root) should have the following structure:

```
sprintsight/                 # the deployment repository — project root
├── backend/                 # cloned from SprintSight_Back
├── frontend/                # cloned from sprint-sight (contains nginx.conf)
├── prediction/              # cloned from Sprint-Sight-AI-API
├── database/
│   └── init-scripts/        # database initialization scripts (run automatically)
├── certs/                   # TLS certificate and key
├── docker-compose.yml       # orchestration file for all four services
└── .env.example             # template for environment configuration
```

All commands in the remaining steps are run from this project root directory.

---

### 5.1.5 Configuration (Environment Variables)

The system is configured through a single `.env` file at the project root. Create it by copying the
provided template:

```bash
cp .env.example .env
```

Then open `.env` in a text editor and set the values. The variables are described below.

**Mandatory — the application will not run correctly until these are set:**

- `DB_PASSWORD` — the password for the PostgreSQL database user. Choose a strong value.
- `JWT_SECRET` — the secret key used to sign authentication tokens. Generate a strong random value
  with:
  ```bash
  openssl rand -base64 64
  ```
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` — credentials for the
  Cloudinary image-hosting service, used for uploading and storing images. These are obtained free of
  charge by creating an account at cloudinary.com. *(If the image-upload feature is not part of your
  demonstration, these may be left as placeholders, but image upload will be unavailable.)*

**Optional — sensible defaults are applied automatically if left unset:**

- `ACTIVE_PROFILES` — backend run profile (default `prod`).
- `DB_NAME`, `DB_USERNAME` — database name and user (default `sprintsight`).
- `DDL_AUTO` — schema-handling mode (default `validate`; the schema is created by the init scripts, so
  this should remain `validate`).
- `JWT_EXPIRATION_MS`, `REFRESH_EXPIRATION_DAYS` — token lifetimes.
- `CORS_ALLOWED_ORIGINS` — the web origin the browser will use to reach the application. For a demo
  accessed on the same machine, set this to `https://localhost`.
---

### 5.1.6 The TLS Certificate

The frontend serves the application over **HTTPS only** and requires a certificate and a private key
to be present at `certs/cert.pem` and `certs/key.pem`. These files are in the deployment repository.

Because it is self-signed, the browser will display a
security warning the first time the site is opened — this is expected for a demo and can be safely
accepted (see step 5.1.9). For a public production deployment, replace these files with a certificate
issued by a trusted Certificate Authority.

---

### 5.1.7 Database Initialization

The PostgreSQL container initializes the database **automatically the first time it starts**, by
executing the scripts in `database/init-scripts/` in alphabetical order:

1. The **schema** script — creates the tables and constraints.
2. The **stored function** script — creates the database functions.
3. The **data-loading** shell script — populates the database with the initial data set.

No manual action is required for this step; it happens during the first run in step 5.1.8.

> **Important:** These scripts run **only once**, when the database storage volume is first created.
> They will *not* run again on subsequent starts. If you need to rebuild the database from scratch (for
> example, to reload the seed data), you must remove the volume — see step 5.1.10.

The loaded data set contains placeholder accounts for demonstration. The only fully functional account
is the seed administrator:

- **Username:** `seed-admin`
- **Password:** `seed-admin`

---

### 5.1.8 Building and Running the System

From the project root, build and start all four services in the background with a single command:

```bash
docker compose up --build -d
```

What to expect:

- **The first build takes several minutes.** The AI prediction image downloads its language model and
  NLTK data, the backend resolves all Maven dependencies, and the frontend installs npm packages and
  produces a production build. Subsequent builds are much faster thanks to Docker's layer cache.
- After the images are built, the containers start **in the correct order automatically.** The database
  starts first, the prediction service loads its model (allow up to two minutes for it to become
  healthy), and only then does the backend start, followed by the frontend.

Monitor progress with:

```bash
docker compose ps          # shows each container's state and health
docker compose logs -f     # streams logs from all services (Ctrl+C to stop following)
```

The system is ready when every container in `docker compose ps` shows status **running** and, where
applicable, **healthy**.

---

### 5.1.9 Verifying the Installation

1. Confirm all four containers are up and healthy:
   ```bash
   docker compose ps
   ```
2. Open a web browser on the host machine and navigate to:
   ```
   https://localhost
   ```
3. Because the certificate is self-signed, the browser will show a security warning. Choose to proceed
   (e.g. *Advanced → Continue to localhost*).
4. Log in with the seed administrator account (`seed-admin` / `seed-admin`) to confirm the full stack —
   frontend, backend, database, and authentication — is working end to end.

If the login page loads and the administrator can sign in, the installation is successful.

---

### 5.1.10 Stopping, Restarting, and Resetting

**Stop the system (data is preserved):**
```bash
docker compose down
```

**Restart after stopping (no rebuild needed):**
```bash
docker compose up -d
```

**Reset completely — stop and erase the database so the init scripts run again on next start:**
```bash
docker compose down -v
```
> The `-v` flag deletes the database volume. All data, including any changes made during use, is
> permanently removed and the seed data is reloaded on the next `docker compose up`.

---

### 5.1.11 Troubleshooting

| Symptom | Likely cause | Resolution |
|---|---|---|
| Frontend container exits immediately | TLS certificate or key missing in `certs/` | Generate the certificate as in step 5.1.6, then run `docker compose up -d` again |
| `port is already allocated` error on start | Ports 80, 443, or 5432 are in use by another program | Stop the conflicting program, or change the host port mapping in `docker-compose.yml` |
| Build error such as missing build context / `path ./backend not found` | A service repository was cloned under the wrong folder name | Re-clone so the three service repos are named exactly `backend`, `frontend`, and `prediction` (step 5.1.4) |
| Prediction container repeatedly restarts or is killed | Insufficient RAM for the AI model | Free up memory or use a machine with at least 8 GB RAM |
| Build fails while downloading the model or dependencies | No internet access during the first build | Ensure the machine is online for the build (internet is also required at run time — see next row) |
| Image upload fails while using the application | No internet access at run time, or invalid Cloudinary credentials | Ensure the machine can reach the internet and that the `CLOUDINARY_*` values in `.env` are correct |
| Seed data did not load / login fails on a re-install | The database volume already existed, so init scripts were skipped | Run `docker compose down -v`, then `docker compose up --build -d` to recreate the database |
| Browser shows a certificate warning | The certificate is self-signed | Expected for the demo — proceed past the warning; use a CA-issued certificate in production |

---

*End of Installation Guide. The remainder of Chapter 5 (the operation walkthrough with annotated
screenshots) follows in the next section.*
