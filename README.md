# go-api-auth-demo

## Features

- **Public Endpoint**: Accessible without authentication.
- **Basic Authentication**: Protects endpoints with user credentials.
- **JWT Authentication**: Generates and verifies JWT tokens for secure access.
- **API Key Authentication**: Protects endpoints with an API key.
- **Automated Tests**: Includes a Makefile for running automated tests.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Gnu Make](https://www.gnu.org/software/make/)

## Installation

### Clone the repository:

 ```bash
 git clone https://github.com/manzolo/go-api-auth-demo.git
 cd go-api-auth-demo
 make build
 make start
 make test
 make stop
```
