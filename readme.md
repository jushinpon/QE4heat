# QE4heat

QE4heat is a set of Perl scripts designed to facilitate and automate tasks related to Quantum ESPRESSO simulations, particularly focusing on heating simulations. Quantum ESPRESSO (QE) is a widely-used open-source suite for electronic-structure calculations and materials modeling. This repository provides tools to streamline the workflow for preparing, submitting, and managing QE heating simulation jobs.

## Features

- **Automated Job Management:** Scripts to monitor, submit, and manage QE heating simulations.
- **Base Configuration Setup:** Tools to prepare base configurations for heating simulations.
- **Cron Job Integration:** Capabilities to schedule periodic tasks for simulation management.
- **Batch Processing:** Support for submitting multiple jobs at once.

## Prerequisites

To use the scripts in this repository, the following prerequisites are required:

1. **Perl:** Ensure that Perl is installed on your system.
2. **Quantum ESPRESSO:** Install QE and configure it to run on your system.
3. **Cluster or HPC Environment:** If running on a computing cluster, ensure access to a job scheduler (e.g., SLURM, PBS).

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/jushinpon/QE4heat.git
   cd QE4heat
   ```

2. Make the scripts executable:

   ```bash
   chmod +x *.pl
   ```

## Usage

### 1. Preparing Base Configurations

Use the `make_base4heat.pl` script to prepare the base configuration files for heating simulations.

```bash
perl make_base4heat.pl
```

### 2. Submitting Jobs

- To submit a new heating simulation job, use the `submit4newHeat.pl` script:

  ```bash
  perl submit4newHeat.pl
  ```

- For batch submission of all base temperature jobs, use the `submit_allbaseTjobs.pl` script:

  ```bash
  perl submit_allbaseTjobs.pl
  ```

### 3. Monitoring Jobs

Monitor the status of QE jobs related to heating simulations with `check_QEjobs4heating.pl`:

```bash
perl check_QEjobs4heating.pl
```

### 4. Updating Input Files

To update Quantum ESPRESSO input files, use the `updated_QEin.pl` script:

```bash
perl updated_QEin.pl
```

### 5. Managing Scheduled Tasks

Use the `create_crontab.pl` script to set up periodic tasks for managing jobs:

```bash
perl create_crontab.pl
```

## Files Overview

| File Name                  | Description                                                 |
|----------------------------|-------------------------------------------------------------|
| `check_QEjobs4heating.pl` | Script to monitor the status of heating simulation jobs.    |
| `create_crontab.pl`       | Script to create and manage cron jobs for job automation.   |
| `make_base4heat.pl`       | Prepares base configuration files for heating simulations.  |
| `submit4newHeat.pl`       | Submits new heating simulation jobs.                        |
| `submit_allbaseTjobs.pl`  | Submits all base temperature jobs in a batch.               |
| `updated_QEin.pl`         | Updates Quantum ESPRESSO input files for simulations.       |

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions, feel free to open an issue or submit a pull request.

## License

This repository is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute the code as per the license terms.

## Acknowledgments

Special thanks to the developers of Quantum ESPRESSO for providing a powerful suite for materials modeling. This repository builds on QE to simplify workflows for heating simulations.

## Contact

For any inquiries, please contact the repository owner through GitHub.
