CloudFormation do

  # Scaling block start
  Condition "AutoScalingEnabled", FnEquals(Ref(:AutoScalingEnabled), 'true')
  Condition "IsScalingMaxOverFive", FnNot(FnOr([
              FnEquals(Ref(:ScalingMax), 1),
              FnEquals(Ref(:ScalingMax), 2),
              FnEquals(Ref(:ScalingMax), 3),
              FnEquals(Ref(:ScalingMax), 4),
              FnEquals(Ref(:ScalingMax), 5)
  ]))
  Output(:IsScalingMaxOverFive) { Value FnIf("IsScalingMaxOverFive", "true", "false") }

  # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-elasticache-replicationgroup.html#cfn-elasticache-replicationgroup-datatieringenabled
  Condition "InstanceSizeFitsTiering", FnOr([
    FnEquals(Ref(:InstanceType), 'cache.r6gd.xlarge'),
    FnEquals(Ref(:InstanceType), 'cache.r6gd.2xlarge'),
    FnEquals(Ref(:InstanceType), 'cache.r6gd.4xlarge'),
    FnEquals(Ref(:InstanceType), 'cache.r6gd.8xlarge'),
    FnEquals(Ref(:InstanceType), 'cache.r6gd.12xlarge'),
    FnEquals(Ref(:InstanceType), 'cache.r6gd.16xlarge')
  ])

  # https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/AutoScaling.html
  Condition "InstanceSizeFitsR7G", FnOr([FnEquals(Ref(:InstanceType), 'cache.r7g.large'), FnEquals(Ref(:InstanceType), 'cache.r7g.xlarge'), FnEquals(Ref(:InstanceType), 'cache.r7g.2xlarge')])
  Condition "InstanceSizeFitsR6G", FnOr([FnEquals(Ref(:InstanceType), 'cache.r6g.large'), FnEquals(Ref(:InstanceType), 'cache.r6g.xlarge'), FnEquals(Ref(:InstanceType), 'cache.r6g.2xlarge')])
  Condition "InstanceSizeFitsR5", FnOr([FnEquals(Ref(:InstanceType), 'cache.r5.large'), FnEquals(Ref(:InstanceType), 'cache.r5.xlarge'), FnEquals(Ref(:InstanceType), 'cache.r5.2xlarge')])
  Condition "InstanceSizeFitsM7G", FnOr([FnEquals(Ref(:InstanceType), 'cache.m7g.large'), FnEquals(Ref(:InstanceType), 'cache.m7g.xlarge'), FnEquals(Ref(:InstanceType), 'cache.m7g.2xlarge')])
  Condition "InstanceSizeFitsM6G", FnOr([FnEquals(Ref(:InstanceType), 'cache.m6g.large'), FnEquals(Ref(:InstanceType), 'cache.m6g.xlarge'), FnEquals(Ref(:InstanceType), 'cache.m6g.2xlarge')])
  Condition "InstanceSizeFitsM5", FnOr([FnEquals(Ref(:InstanceType), 'cache.m5.large'), FnEquals(Ref(:InstanceType), 'cache.m5.xlarge'), FnEquals(Ref(:InstanceType), 'cache.m5.2xlarge')])
  Condition "InstanceSizeFitsC7GN", FnOr([FnEquals(Ref(:InstanceType), 'cache.c7gn.large'), FnEquals(Ref(:InstanceType), 'cache.c7gn.xlarge'), FnEquals(Ref(:InstanceType), 'cache.c7gn.2xlarge')])
  Condition "InstanceSizeFitsR6GD", FnOr([FnEquals(Ref(:InstanceType), 'cache.r6gd.large'), FnEquals(Ref(:InstanceType), 'cache.r6gd.xlarge'), FnEquals(Ref(:InstanceType), 'cache.r6gd.2xlarge')])

  Condition "InstanceSizeFits", FnOr([
    Condition("InstanceSizeFitsR7G"),
    Condition("InstanceSizeFitsR6G"),
    Condition("InstanceSizeFitsR5"),
    Condition("InstanceSizeFitsM7G"),
    Condition("InstanceSizeFitsM6G"),
    Condition("InstanceSizeFitsM5"),
    Condition("InstanceSizeFitsC7GN"),
    Condition("InstanceSizeFitsR6GD")
  ])
  Output(:InstanceSizeFits) { Value FnIf("InstanceSizeFits", "true", "false") }
  
  Condition "AutoScalingAllowed", FnAnd([ Condition("AutoScalingEnabled"), Condition("InstanceSizeFits")])
  Output(:AutoScalingAllowed) { Value FnIf("AutoScalingAllowed", "true", "false") }
  # Scaling block end

  export = external_parameters.fetch(:export_name, external_parameters[:component_name])
  
  redis_tags = []
  redis_tags << { Key: 'Name', Value: FnSub("${EnvironmentName}-#{export}") }
  redis_tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
  redis_tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }

  tags = external_parameters.fetch(:tags, {})
  tags.each do |key, value|
    redis_tags << { Key: FnSub(key), Value: FnSub(value)}
  end
  
  ip_blocks = external_parameters.fetch(:ip_blocks, {})
  security_group_rules = external_parameters.fetch(:security_group_rules, [])

  EC2_SecurityGroup(:SecurityGroupRedis) {
    VpcId Ref(:VPCId)
    GroupDescription FnSub("${EnvironmentName}-#{export}")
    
    if security_group_rules.any?
      SecurityGroupIngress generate_security_group_rules(security_group_rules,ip_blocks)
    end

    SecurityGroupEgress([
      {
        CidrIp: '0.0.0.0/0',
        Description: 'Outbound for all ports',
        IpProtocol: '-1',
      }
    ])

    Tags redis_tags
  }

  Output(:RedisSecurityGroupId) {
    Value Ref(:SecurityGroupRedis)
    Export FnSub("${EnvironmentName}-#{export}-RedisSecurityGroup")
  }

  ElastiCache_SubnetGroup(:SubnetGroupRedis) {
    Description FnSub("${EnvironmentName}-#{export}")
    SubnetIds Ref(:Subnets)
  }

  custom_parameters = external_parameters.fetch(:parameters, [])
  family = external_parameters.fetch(:family, 'redis6.x')
  cluster_enabled = external_parameters.fetch(:cluster_enabled, 'true')

  if cluster_enabled
    record_endpoint = 'ConfigurationEndPoint.Address'
    final_parameters = { 'cluster-enabled': 'yes' }
  else 
    record_endpoint = 'PrimaryEndPoint.Address'
    final_parameters = { 'cluster-enabled': 'no' }
  end

  final_parameters.merge!(custom_parameters) unless custom_parameters.empty?

  ElastiCache_ParameterGroup(:ParameterGroupRedis) {
    CacheParameterGroupFamily family
    Description FnSub("${EnvironmentName}-#{export}")
    Properties final_parameters
  }

  engine_version = external_parameters.fetch(:engine_version, nil)
  redis_port = external_parameters.fetch(:redis_port, nil)

  transit_encryption = external_parameters.fetch(:transit_encryption, true)
  transit_encryption_mode = external_parameters.fetch(:transit_encryption_mode, '')
  at_rest_encryption = external_parameters.fetch(:at_rest_encryption, true)
  kms_key_id = external_parameters.fetch(:kms_key_id, nil)

  minor_upgrade = external_parameters.fetch(:minor_upgrade, true)
  snapshot_window = external_parameters.fetch(:snapshot_window, nil)
  maintenance_window = external_parameters.fetch(:maintenance_window, nil)

  replication_mode = external_parameters.fetch(:replication_mode, 'node_group')
  automatic_failover = external_parameters.fetch(:automatic_failover, true)

  Condition('DataTieringEnabled', FnEquals(Ref(:DataTieringEnabled), 'true'))
  Condition('DaraTieringAllowed', FnAnd([ Condition("InstanceSizeFitsTiering"), Condition("DataTieringEnabled") ]))

  Condition('NoSnapshotNameEnabled', FnEquals(Ref(:SnapshotName), ''))
  Condition('NoSnapshotArnsEnabled', FnEquals(Ref(:SnapshotArns), ''))

  engine = external_parameters.fetch(:engine, 'redis')

  ElastiCache_ReplicationGroup(:ReplicationGroupRedis) {

    UpdatePolicy "UseOnlineResharding", Ref(:UseOnlineResharding)

    ReplicationGroupDescription FnSub("${EnvironmentName}-#{export}")

    Engine engine
    EngineVersion engine_version unless engine_version.nil?
    Port redis_port unless redis_port.nil?

    TransitEncryptionEnabled transit_encryption
    TransitEncryptionMode transit_encryption_mode if !transit_encryption_mode.empty?
    AtRestEncryptionEnabled at_rest_encryption
    KmsKeyId kms_key_id if (at_rest_encryption == true) && (!kms_key_id.nil?)
    AutoMinorVersionUpgrade minor_upgrade
    AutomaticFailoverEnabled automatic_failover

    DataTieringEnabled FnIf('DaraTieringAllowed', 'true', Ref('AWS::NoValue'))
    MultiAZEnabled Ref(:MultiAZEnabled)

    CacheNodeType Ref(:InstanceType)
    CacheParameterGroupName Ref(:ParameterGroupRedis)
    CacheSubnetGroupName Ref(:SubnetGroupRedis)

    SecurityGroupIds [ Ref(:SecurityGroupRedis) ]
    
    if replication_mode.eql?('node_group')
      NumNodeGroups Ref(:NumNodeGroups)
      ReplicasPerNodeGroup Ref(:ReplicasPerNodeGroup)
    elsif replication_mode.eql?('cache_cluster')
      NumCacheClusters Ref(:NumCacheClusters)
    end 

    SnapshotName FnIf('NoSnapshotNameEnabled', Ref('AWS::NoValue'), Ref(:SnapshotName))
    SnapshotArns FnIf('NoSnapshotArnsEnabled', Ref('AWS::NoValue'), FnSplit(",", Ref(:SnapshotArns)))
    SnapshotRetentionLimit Ref(:SnapshotRetentionLimit)

    SnapshotWindow snapshot_window unless snapshot_window.nil?
    PreferredMaintenanceWindow maintenance_window unless maintenance_window.nil?

    Tags redis_tags

  }

  dns_domain = external_parameters.fetch(:dns_domain)
  record = external_parameters.fetch(:record, 'redis')

  if external_parameters[:create_route53_record]
    Route53_RecordSet(:HostRecordRedis) {
      HostedZoneName FnSub("#{dns_domain}.")
      Name FnSub("#{record}.#{dns_domain}.")
      Type 'CNAME'
      TTL '60'
      ResourceRecords [ FnGetAtt(:ReplicationGroupRedis, record_endpoint) ]
    }
  end

  Output(:RedisHostEndpoint) {
    Value(FnGetAtt(:ReplicationGroupRedis, record_endpoint))
    Export FnSub("${EnvironmentName}-#{export}-RedisHostEndpoint")
  }

  Output(:RedisReadAddresses) {
    Value(FnGetAtt(:ReplicationGroupRedis, 'ReadEndPoint.Addresses'))
    Export FnSub("${EnvironmentName}-#{export}-RedisReadAddresses")
  } unless cluster_enabled

 # Autoscaling block end
  IAM_Role(:ServiceElastiCacheAutoScaleRole) do
    Condition "AutoScalingAllowed"
    AssumeRolePolicyDocument service_assume_role_policy('application-autoscaling')
    Path '/'
    Policies ([
      PolicyName: 'elasticache-scaling',
      PolicyDocument: {
        Statement: [
          {
            Effect: "Allow",
            Action: ['cloudwatch:DescribeAlarms','cloudwatch:PutMetricAlarm','cloudwatch:DeleteAlarms'],
            Resource: "*"
          },
          {
            Effect: "Allow",
            Action: [
              "elasticache:Describe*",
              "elasticache:IncreaseReplicaCount",
              "elasticache:DecreaseReplicaCount",
              "elasticache:ModifyReplicationGroupShardConfiguration"
            ],
            Resource: [
               FnJoin('', [ FnSub("arn:aws:elasticache:${AWS::Region}:${AWS::AccountId}:cluster:"), FnSelect(0, FnSplit('.', FnGetAtt(:ReplicationGroupRedis, record_endpoint))), "*"]),
               FnJoin('', [ FnSub("arn:aws:elasticache:${AWS::Region}:${AWS::AccountId}:replicationgroup:"), FnSelect(0, FnSplit('.', FnGetAtt(:ReplicationGroupRedis, record_endpoint)))])
            ]
          }
        ]
    }])
  end

  # Supports only TargetTrackingScaling
  scaling_policy = external_parameters.fetch(:scaling_policy, {})
  scaling_policy.each_with_index do |scale_target_policy, i|

    ApplicationAutoScaling_ScalableTarget("ServiceScalingTarget" + (i > 0 ? "#{i+1}" : "")) do
      Condition "AutoScalingAllowed"
      DependsOn [:ServiceElastiCacheAutoScaleRole]
      if (scale_target_policy['target'] == 'replicas')
        MaxCapacity FnIf('IsScalingMaxOverFive', 5, Ref(:ScalingMax))
      else
        MaxCapacity Ref(:ScalingMax)
      end
      MinCapacity Ref(:ScalingMin)
      ResourceId FnJoin('', ["replication-group/", FnSelect(0, FnSplit('.', FnGetAtt(:ReplicationGroupRedis, record_endpoint)))])
      RoleARN FnGetAtt(:ServiceElastiCacheAutoScaleRole, :Arn)
      if (scale_target_policy['target'] == 'replicas') 
        ScalableDimension "elasticache:replication-group:Replicas"
      elsif (scale_target_policy['target'] == 'shards')
        ScalableDimension "elasticache:replication-group:NodeGroups"
      else
        ScalableDimension "elasticache:replication-group:Replicas"
      end
      ServiceNamespace "elasticache"
    end

    logical_scaling_policy_name = "ServiceTargetTrackingPolicy" + (i > 0 ? "#{i+1}" : "")
    policy_name = "target-tracking-policy" + (i > 0 ? "-#{i+1}" : "")

    ApplicationAutoScaling_ScalingPolicy(logical_scaling_policy_name) do
      Condition "AutoScalingAllowed"
      DependsOn ["ServiceScalingTarget" + (i > 0 ? "#{i+1}" : "")]
      PolicyName FnJoin('-', [ Ref('EnvironmentName'), component_name, policy_name])
      PolicyType 'TargetTrackingScaling'
      ScalingTargetId Ref("ServiceScalingTarget" + (i > 0 ? "#{i+1}" : ""))
      TargetTrackingScalingPolicyConfiguration do
        TargetValue scale_target_policy['target_value'] || 70
        ScaleInCooldown scale_target_policy['scale_in_cooldown'].to_s unless scale_target_policy['scale_in_cooldown'].nil?
        ScaleOutCooldown scale_target_policy['scale_out_cooldown'].to_s unless scale_target_policy['scale_out_cooldown'].nil?
        PredefinedMetricSpecification do
          PredefinedMetricType scale_target_policy['metric_type'] || 'ElastiCacheReplicaEngineCPUUtilization'
        end unless scale_target_policy['metric_type'].nil?
        CustomizedMetricSpecification do
          Namespace scale_target_policy['customized']['namespace'] unless scale_target_policy['customized']['namespace'].nil?
          MetricName scale_target_policy['customized']['metric_name'] unless scale_target_policy['customized']['metric_name'].nil?
          Statistic scale_target_policy['customized']['statistic'] unless scale_target_policy['customized']['statistic'].nil?
          Unit scale_target_policy['customized']['unit'] unless scale_target_policy['customized']['unit'].nil?
          Dimensions scale_target_policy['customized']['dimensions'] unless scale_target_policy['customized']['dimensions'].nil?
        end unless scale_target_policy['customized'].nil?
      end
    end

  end unless scaling_policy.nil?
  # Autoscaling block end

end
