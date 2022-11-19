# ArgoCD Example

- Create a database password for the `DBInstance` that the ACK RDS Controller will have to create when you will deploy the `back` app.

    ```bash
    # The additional space in the next command is here on purpose to avoid inserting the command with your password in the shell history
    ❯ kubectl create ns back
    ❯  kubectl -n back create secret generic "back-password" --from-literal=password="<your DBInstance password>"
    ```

- Create the ArgoCD App of Apps for our demo

    ```bash
    ❯ argocd app create crossplane-ack-meetup --repo https://github.com/pdemagny/crossplane-ack-meetup.git --path ./examples/argocd --dest-server https://kubernetes.default.svc --revision main --project default --dest-namespace argocd
    ❯ argocd app sync argocd/crossplane-ack-meetup
    ```
