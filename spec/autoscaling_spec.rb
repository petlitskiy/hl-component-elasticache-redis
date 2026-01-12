require 'yaml'

describe 'compiled component redis' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/default.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/default/redis.compiled.yaml") }
  
  context "Resource" do

    
    context "SecurityGroupRedis" do
      let(:resource) { template["Resources"]["SecurityGroupRedis"] }

      it "is of type AWS::EC2::SecurityGroup" do
          expect(resource["Type"]).to eq("AWS::EC2::SecurityGroup")
      end
      
      it "to have property VpcId" do
          expect(resource["Properties"]["VpcId"]).to eq({"Ref"=>"VPCId"})
      end
      
      it "to have property GroupDescription" do
          expect(resource["Properties"]["GroupDescription"]).to eq({"Fn::Sub"=>"${EnvironmentName}-redis"})
      end
      
      it "to have property SecurityGroupEgress" do
          expect(resource["Properties"]["SecurityGroupEgress"]).to eq([{"CidrIp"=>"0.0.0.0/0", "Description"=>"Outbound for all ports", "IpProtocol"=>"-1"}])
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-redis"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
    context "SubnetGroupRedis" do
      let(:resource) { template["Resources"]["SubnetGroupRedis"] }

      it "is of type AWS::ElastiCache::SubnetGroup" do
          expect(resource["Type"]).to eq("AWS::ElastiCache::SubnetGroup")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName}-redis"})
      end
      
      it "to have property SubnetIds" do
          expect(resource["Properties"]["SubnetIds"]).to eq({"Ref"=>"Subnets"})
      end
      
    end
    
    context "ParameterGroupRedis" do
      let(:resource) { template["Resources"]["ParameterGroupRedis"] }

      it "is of type AWS::ElastiCache::ParameterGroup" do
          expect(resource["Type"]).to eq("AWS::ElastiCache::ParameterGroup")
      end
      
      it "to have property CacheParameterGroupFamily" do
          expect(resource["Properties"]["CacheParameterGroupFamily"]).to eq("redis6.x")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName}-redis"})
      end
      
      it "to have property Properties" do
          expect(resource["Properties"]["Properties"]).to eq({"cluster-enabled"=>"yes"})
      end
      
    end
    
    context "ReplicationGroupRedis" do
      let(:resource) { template["Resources"]["ReplicationGroupRedis"] }

      it "is of type AWS::ElastiCache::ReplicationGroup" do
          expect(resource["Type"]).to eq("AWS::ElastiCache::ReplicationGroup")
      end
      
      it "to have property ReplicationGroupDescription" do
          expect(resource["Properties"]["ReplicationGroupDescription"]).to eq({"Fn::Sub"=>"${EnvironmentName}-redis"})
      end
      
      it "to have property Engine" do
          expect(resource["Properties"]["Engine"]).to eq("redis")
      end
      
      it "to have property TransitEncryptionEnabled" do
          expect(resource["Properties"]["TransitEncryptionEnabled"]).to eq(true)
      end
      
      it "to have property AtRestEncryptionEnabled" do
          expect(resource["Properties"]["AtRestEncryptionEnabled"]).to eq(true)
      end
      
      it "to have property AutoMinorVersionUpgrade" do
          expect(resource["Properties"]["AutoMinorVersionUpgrade"]).to eq(true)
      end
      
      it "to have property AutomaticFailoverEnabled" do
          expect(resource["Properties"]["AutomaticFailoverEnabled"]).to eq(true)
      end
      
      it "to have property DataTieringEnabled" do
          expect(resource["Properties"]["DataTieringEnabled"]).to eq({"Fn::If"=>["DataTieringEnabled", {"Ref"=>"DataTieringEnabled"}, {"Ref"=>"AWS::NoValue"}]})
      end
      
      it "to have property CacheNodeType" do
          expect(resource["Properties"]["CacheNodeType"]).to eq({"Ref"=>"InstanceType"})
      end
      
      it "to have property CacheParameterGroupName" do
          expect(resource["Properties"]["CacheParameterGroupName"]).to eq({"Ref"=>"ParameterGroupRedis"})
      end
      
      it "to have property CacheSubnetGroupName" do
          expect(resource["Properties"]["CacheSubnetGroupName"]).to eq({"Ref"=>"SubnetGroupRedis"})
      end
      
      it "to have property SecurityGroupIds" do
          expect(resource["Properties"]["SecurityGroupIds"]).to eq([{"Ref"=>"SecurityGroupRedis"}])
      end
      
      it "to have property NumNodeGroups" do
          expect(resource["Properties"]["NumNodeGroups"]).to eq({"Ref"=>"NumNodeGroups"})
      end
      
      it "to have property ReplicasPerNodeGroup" do
          expect(resource["Properties"]["ReplicasPerNodeGroup"]).to eq({"Ref"=>"ReplicasPerNodeGroup"})
      end
      
      it "to have property SnapshotName" do
          expect(resource["Properties"]["SnapshotName"]).to eq({"Fn::If"=>["NoSnapshotNamEnabled", {"Ref"=>"AWS::NoValue"}, {"Ref"=>"SnapshotName"}]})
      end
      
      it "to have property SnapshotArns" do
          expect(resource["Properties"]["SnapshotArns"]).to eq({"Fn::If"=>["NoSnapshotArnsEnabled", {"Ref"=>"AWS::NoValue"}, {"Fn::Split"=>[",", {"Ref"=>"SnapshotArns"}]}]})
      end
      
      it "to have property SnapshotRetentionLimit" do
          expect(resource["Properties"]["SnapshotRetentionLimit"]).to eq({"Ref"=>"SnapshotRetentionLimit"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-redis"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
    context "HostRecordRedis" do
      let(:resource) { template["Resources"]["HostRecordRedis"] }

      it "is of type AWS::Route53::RecordSet" do
          expect(resource["Type"]).to eq("AWS::Route53::RecordSet")
      end
      
      it "to have property HostedZoneName" do
          expect(resource["Properties"]["HostedZoneName"]).to eq({"Fn::Sub"=>"${EnvironmentName}.${DnsDomain}."})
      end
      
      it "to have property Name" do
          expect(resource["Properties"]["Name"]).to eq({"Fn::Sub"=>"redis.${EnvironmentName}.${DnsDomain}."})
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("CNAME")
      end
      
      it "to have property TTL" do
          expect(resource["Properties"]["TTL"]).to eq("60")
      end
      
      it "to have property ResourceRecords" do
          expect(resource["Properties"]["ResourceRecords"]).to eq([{"Fn::GetAtt"=>["ReplicationGroupRedis", "ConfigurationEndPoint.Address"]}])
      end
      
    end
    
  end

end