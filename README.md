# Observability
## Project details and Services used
The application is deployed on **AWS** and utilizes **Terraform** to orchestrate the provisioning of multiple EC2 instances in different availability zones thereby creatinging a **highly available** architecture.
It employs **Terraform** as Infrastructure as Code (**IaC**) to automate the entire infrastructure stack and securely stores the state on an S3 remote backend, boosting efficiency and reducing operational overhead.
it leverages **Ansible** for the configuration and orchestration of the **static web hosting**, along with the observability and monitoring infrastructure across the multiple EC2 instances, ensuring smooth and efficient operations.
These observability and monitoring infrastructures:  ***Prometheus***, ***Grafana***, and ***Node Exporter*** are integrated to deliver real-time insights and performance metrics.
