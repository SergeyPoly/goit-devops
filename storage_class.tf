# Дефолтний StorageClass на базі aws-ebs-csi-driver.
# Вбудований "gp2" (in-tree kubernetes.io/aws-ebs) не позначений default
# і використовує застарілий провіжинер, тому PVC (Jenkins) зависають у Pending.
# Живе поза модулем eks: інакше виникає цикл провайдера kubernetes, який тут
# налаштований через data.aws_eks_cluster/data.aws_eks_cluster_auth, що самі
# залежать від повного завершення module.eks.
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }

  depends_on = [module.eks]
}
