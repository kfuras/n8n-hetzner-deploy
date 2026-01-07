.PHONY: help deploy deploy-verbose check services restart logs update backup ping install-requirements

help:
	@echo "n8n Hetzner Deployment - Ansible Commands"
	@echo ""
	@echo "Usage:"
	@echo "  make deploy              Deploy n8n and all enabled services"
	@echo "  make deploy-verbose      Deploy with detailed task output"
	@echo "  make check               Check DNS propagation"
	@echo "  make services            Show running services"
	@echo "  make restart service=X   Restart specific service (or all if not specified)"
	@echo "  make logs service=X      View logs for specific service (last 100 lines)"
	@echo "  make update              Pull latest changes and update deployment"
	@echo "  make backup              Backup databases"
	@echo "  make ping                Test connection to server"
	@echo "  make install-requirements Install Ansible requirements"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy"
	@echo "  make deploy-verbose"
	@echo "  make restart service=traefik"
	@echo "  make logs service=n8n"

deploy:
	@cd ansible && ansible-playbook playbooks/site.yml

deploy-verbose:
	@cd ansible && ansible-playbook playbooks/site.yml -v

check:
	@cd ansible && ansible all -m shell -a "dig +short n8n.$$(grep '^domain:' group_vars/all/infrastructure.yml | awk '{print $$2}') @1.1.1.1"

services:
	@cd ansible && ansible all -m shell -a "cd /home/$$(grep '^username:' group_vars/all/infrastructure.yml | awk '{print $$2}')/stack && docker compose ps"

restart:
ifdef service
	@cd ansible && ansible-playbook playbooks/restart.yml -e "service=$(service)"
else
	@cd ansible && ansible-playbook playbooks/restart.yml
endif

logs:
ifndef service
	$(error service is required. Usage: make logs service=n8n)
endif
	@cd ansible && ansible all -m shell -a "cd /home/$$(grep '^username:' group_vars/all.yml | awk '{print $$2}')/stack && docker compose logs --tail=100 $(service)"

update:
	@cd ansible && ansible-playbook playbooks/update.yml

backup:
	@cd ansible && ansible-playbook playbooks/backup.yml

ping:
	@cd ansible && ansible all -m ping

install-requirements:
	@ansible-galaxy collection install community.docker
