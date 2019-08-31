%% LSTM  ��������LSTM
clear
clc
close all
%% ��������
clear;clc;close all;format compact
%% ��������
qx1=xlsread('���������ն�����.xlsx','B2:G362');%������ȱʧֵ�����ֻ����ǰ���к�����У��м伸��û�ж�ȡ
qx2=xlsread('���������ն�����.xlsx','J2:O362');
qx=[qx1 qx2];
wr=xlsread('������Ⱦ�ն�����.xlsx','C2:C362');
input=[wr(1:end-1,:) qx(2:end,:)];%����Ϊǰһ���pm2.5+Ԥ���յ�����  ���ΪԤ���յ�pm2.5
output=wr(2:end,:);
P=mapminmax(input',0,1);
[T,outputns]=mapminmax(output',0,1);

%% ��ȡ300������Ϊѵ��������ʣ������ΪԤ������

n=1:size(P,2);
i=300;
train_data=P(:,n(1:i));
train_label=T(:,n(1:i),:);
P_test=P(:,n(i+1:end));
T_test=T(:,n(i+1:end));

data_length=size(train_data,1);
% ����minibatch��������ѵ�� ������Ҫ��ѵ�����ݽ��з���
%��numbatches�� ÿ��data_num�� ��numbatches*data_num������
numbatches=3;
data_num=100;
for i=1:numbatches
    train1=train_data(:,(i-1)*data_num+1:i*data_num);
    batchdata(:,:,i)=train1;
end

for i=1:numbatches
    train2=train_label(:,(i-1)*data_num+1:i*data_num);
    batchdata_target(:,:,i)=train2;
end
%% ���������ʼ��
% ���������
input_num=data_length;%�����ڵ�
cell_num=5;%������ڵ�
output_num=1;%�����ڵ�
dropout=0;%dropoutϵ��
cost_gate=1e-10;% ���Ҫ�󾫶�
% ab=20;
ab=4*sqrt(6/(cell_num+output_num));%  ���þ��ȷֲ����г�ʼ��
% ab=1/ab;

%% �����ʼ��
% ����ƫ�ó�ʼ��
bias_input_gate=rand(1,cell_num);
bias_forget_gate=rand(1,cell_num);
bias_output_gate=rand(1,cell_num);
% ����Ȩ�س�ʼ��
weight_input_x=rand(input_num,cell_num)/ab;
weight_input_h=rand(output_num,cell_num)/ab;
weight_inputgate_x=rand(input_num,cell_num)/ab;
weight_inputgate_c=rand(cell_num,cell_num)/ab;
weight_forgetgate_x=rand(input_num,cell_num)/ab;
weight_forgetgate_c=rand(cell_num,cell_num)/ab;
weight_outputgate_x=rand(input_num,cell_num)/ab;
weight_outputgate_c=rand(cell_num,cell_num)/ab;
% hidden_outputȨ��
weight_preh_h=rand(cell_num,output_num);
% ����״̬��ʼ��
h_state=rand(output_num,data_num);
cell_state=rand(cell_num,data_num);
%% ����ѵ��ѧϰ
for iter=1:100%ѵ������
    yita=1/(10+sqrt(iter)); %����Ӧѧϰ��
    for n=1:numbatches%����minibatch��ʽ����ѵ��
        train_data=batchdata(:,:,n);
        train_label=batchdata_target(:,:,n);
    for m=1:data_num
        %ǰ������
        if(m==1)
            gate=tanh(train_data(:,m)'*weight_input_x);
            input_gate_input=train_data(:,m)'*weight_inputgate_x+bias_input_gate;
            output_gate_input=train_data(:,m)'*weight_outputgate_x+bias_output_gate;
            for n=1:cell_num
                input_gate(1,n)=1/(1+exp(-input_gate_input(1,n)));
                output_gate(1,n)=1/(1+exp(-output_gate_input(1,n)));
            end
            forget_gate=zeros(1,cell_num);
            forget_gate_input=zeros(1,cell_num);
            cell_state(:,m)=(input_gate.*gate)';
        else
            gate=tanh(train_data(:,m)'*weight_input_x+h_state(:,m-1)'*weight_input_h);
            input_gate_input=train_data(:,m)'*weight_inputgate_x+cell_state(:,m-1)'*weight_inputgate_c+bias_input_gate;
            forget_gate_input=train_data(:,m)'*weight_forgetgate_x+cell_state(:,m-1)'*weight_forgetgate_c+bias_forget_gate;
            output_gate_input=train_data(:,m)'*weight_outputgate_x+cell_state(:,m-1)'*weight_outputgate_c+bias_output_gate;
            for n=1:cell_num
                input_gate(1,n)=1/(1+exp(-input_gate_input(1,n)));
                forget_gate(1,n)=1/(1+exp(-forget_gate_input(1,n)));
                output_gate(1,n)=1/(1+exp(-output_gate_input(1,n)));
            end
            cell_state(:,m)=(input_gate.*gate+cell_state(:,m-1)'.*forget_gate)';   
        end
        pre_h_state=tanh(cell_state(:,m)').*output_gate;
        h_state(:,m)=(pre_h_state*weight_preh_h)';
        %������
        Error=h_state(:,m)-train_label(:,m);
        Error_Cost(1,iter)=sum(Error.^2);
        if(Error_Cost(1,iter)<cost_gate)
            flag=1;
            break;
        else %Ȩ�ظ���
            [   weight_input_x,...
                weight_input_h,...
                weight_inputgate_x,...
                weight_inputgate_c,...
                weight_forgetgate_x,...
                weight_forgetgate_c,...
                weight_outputgate_x,...
                weight_outputgate_c,...
                weight_preh_h ]=LSTM_updata_weight(cell_num,output_num,m,yita,Error,...
                                                   weight_input_x,...
                                                   weight_input_h,...
                                                   weight_inputgate_x,...
                                                   weight_inputgate_c,...
                                                   weight_forgetgate_x,...
                                                   weight_forgetgate_c,...
                                                   weight_outputgate_x,...
                                                   weight_outputgate_c,...
                                                   weight_preh_h,...
                                                   cell_state,h_state,...
                                                   input_gate,forget_gate,...
                                                   output_gate,gate,...
                                                   train_data,pre_h_state,...
                                                   input_gate_input,...
                                                   output_gate_input,...
                                                   forget_gate_input);
                
        end
    end
    if(dropout>0) %Dropout
        rand('seed',0)
           weight_inputgate_x =weight_inputgate_x.*(rand(size(weight_inputgate_x))>dropout);
    end
       
    if(Error_Cost(1,iter)<cost_gate)
        break;
    end
    end
end
%% ���Խ׶�
%���ݼ���
for i=1:size(P_test,2)
test_final=P_test(:,i);
test_output=T_test(:,i);
%ǰ��
m=2;
gate=tanh(test_final'*weight_input_x+h_state(:,m-1)'*weight_input_h);
input_gate_input=test_final'*weight_inputgate_x+cell_state(:,m-1)'*weight_inputgate_c+bias_input_gate;
forget_gate_input=test_final'*weight_forgetgate_x+cell_state(:,m-1)'*weight_forgetgate_c+bias_forget_gate;
output_gate_input=test_final'*weight_outputgate_x+cell_state(:,m-1)'*weight_outputgate_c+bias_output_gate;
for n=1:cell_num
    input_gate(1,n)=1/(1+exp(-input_gate_input(1,n)));
    forget_gate(1,n)=1/(1+exp(-forget_gate_input(1,n)));
    output_gate(1,n)=1/(1+exp(-output_gate_input(1,n)));
end
cell_state_test=(input_gate.*gate+cell_state(:,m-1)'.*forget_gate)';
pre_h_state=tanh(cell_state_test').*output_gate;
h_state_test=(pre_h_state*weight_preh_h)';

sim(:,i)=h_state_test;
end

%����һ��
test_sim=mapminmax('reverse',sim,outputns);%����Ԥ������
test=mapminmax('reverse',T_test,outputns);%ʵ������

%%
%%
figure
plot(test_sim,'-bo');
grid on
hold on
plot(test,'-r*');
legend('Ԥ������','ʵ������')
title('LSTM������ع�Ԥ��')
xlabel('������')
ylabel('PM2.5����')
% ������
figure
bar(abs(test-test_sim)./test)
title('LSTM')
ylabel('������')
xlabel('������')
% ƽ��������
pjxd=sum(abs(test-test_sim)./test)/length(test)