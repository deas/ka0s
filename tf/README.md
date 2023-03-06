# Terraform Infra for ka0s

## Usage

See [main documentation](../README.md)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_keys | n/a | `map(any)` | `{}` | no |
| bootstrap\_path | Bootstrap path to yaml we apply before flux | `string` | `null` | no |
| dns\_hosts | n/a | `map(string)` | `null` | no |
| filename\_flux\_path | n/a | `string` | `"../simple/clusters/local/flux-system"` | no |
| id\_rsa\_ro\_path | n/a | `string` | `null` | no |
| id\_rsa\_ro\_pub\_path | n/a | `string` | `null` | no |
| kind\_cluster\_name | Cluster name | `string` | `"ka0s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster | Object describing the whole created project |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->