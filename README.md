# AWS Cloud Resume Challenge - Frontend Website Content

![Alt text](<static/img/infra_diagram.png>)
## Project Description

The AWS Cloud Resume Challenge Front-End repository is designed to host a simple and elegant resume website on Amazon S3. This project demonstrates your web development skills and showcases your resume online. This challenge is inspired by Forrest Brazzeal https://cloudresumechallenge.dev/docs/the-challenge/aws/.


## Key Features

- **Website Hosting**
  - Amazon S3: Utilizes Amazon S3 for static content storage, ensuring scalability and high availability.
  - Amazon CloudFront: Leverages Amazon CloudFront as a content delivery network (CDN) to offer globally low-latency, high-performance website access.
  - Amazon Route 53: Configures Amazon Route 53 to associate a custom domain name (resume.heonjaeshin.com) with the CloudFront distribution.
  - AWS Certificate Manager (ACM): Provides SSL/TLS certificates for secure connections.
  - HTML & CSS: Develops the website using HTML and CSS for a visually appealing and responsive design.
  
- **CI/CD Integration**
  - GitHub Actions: Establishes CI/CD pipelines using GitHub Actions.
  - Automated Updates: Automatically updates the website as code is pushed to the Git repository.
  
- **Visitor Count Tracking**
  - API Gateway: Sets up an API Gateway to interact with the backend services.
  - AWS Lambda: Uses AWS Lambda to retrieve view counts from DynamoDB.
  - DynamoDB: Stores and manages visitor count data in Amazon DynamoDB.
  - JavaScript: Integrates JavaScript code to display and update visitor counts on the website in real-time.

## Prerequisites

Before you get started with this project, ensure that you have the following prerequisites in place:

- AWS account for hosting the website (S3 and optionally CloudFront)
- Basic knowledge of web development (HTML, CSS, JavaScript)
- Familiarity with version control using Git and a GitHub account

## Contact

For inquiries or feedback, reach out through the following channels:

- Email: heonjae.shin00@mail.com
- Linkedin: https://www.linkedin.com/in/heonjae-shin-933a4a208/
- GitHub: [Your GitHub Profile](https://github.com/heonjaes)

## Acknowledgments
We extend our thanks to the open-source community and AWS for providing the tools and resources that made this project possible.

