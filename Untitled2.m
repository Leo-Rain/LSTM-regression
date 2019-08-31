%% �˳���Ϊ������ѵ����lstm
clear;clc;close all;format compact
%% ��������
load data
load outputps
train_data=X_train;
train_label=Y_train;
P_test=X_test;
T_test=Y_test;

data_length=size(train_data,1);
data_num=size(train_data,2);
%% ���������ʼ��
% ���������
input_num=data_length;%�����ڵ�
cell_num=3;%������ڵ�
output_num=1;%�����ڵ�
dropout=0.5;%dropoutϵ��
cost_gate=1e-10;% ���Ҫ�󾫶�
ab=4*sqrt(6/(cell_num+output_num));%  ���þ��ȷֲ����г�ʼ��
% �������ŵ�ƫ��
bias_input_gate=rand(1,cell_num);
bias_forget_gate=rand(1,cell_num);
bias_output_gate=rand(1,cell_num);
%% ����Ȩ�س�ʼ��
weight_input_x=rand(input_num,cell_num)/ab;
weight_input_h=rand(output_num,cell_num)/ab;
weight_inputgate_x=rand(input_num,cell_num)/ab;
weight_inputgate_c=rand(cell_num,cell_num)/ab;
weight_forgetgate_x=rand(input_num,cell_num)/ab;
weight_forgetgate_c=rand(cell_num,cell_num)/ab;
weight_outputgate_x=rand(input_num,cell_num)/ab;
weight_outputgate_c=rand(cell_num,cell_num)/ab;
%hidden_outputȨ��
weight_preh_h=rand(cell_num,output_num);
%����״̬��ʼ��
h_state=rand(output_num,data_num);
cell_state=rand(cell_num,data_num);
%% ����ѵ��ѧϰ
for iter=1:100%ѵ������
%     iter
    yita=0.01;
%         yita=1/(10+sqrt(iter)); %����Ӧѧϰ��
    
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
end
% figure
% plot(Error_Cost)
% xlabel('��������')
% ylabel('ѵ�����')
% title('LSTMѵ���������')
%% ���Խ׶�
%���ݼ���
load data_lstm
for i=1:size(P_test,2)
    test_final=P_test(:,i);
    %ǰ��
    m=data_num;
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
%% ����һ��
test_sim=mapminmax('reverse',sim,outputps);%����Ԥ������
% test=mapminmax('reverse',T_test,outputps);%ʵ������
test=T_test;%ʵ������

%
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
plot(abs(test-test_sim)./test)
title('LSTM')
ylabel('������')
xlabel('������')
% ƽ��������
pjxd=sum(abs(test-test_sim)./test)/length(test)