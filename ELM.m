%% ��ջ������� elm
clc
clear
close all
format compact
%% ��������
load data
load outputps
P_train=X_train;
T_train=Y_train;
P_test=X_test;
T_test=Y_test;
%% ��ȡ300������Ϊѵ��������ʣ������ΪԤ������

%% �ڵ����
inputnum=size(P_train,1);%�����ڵ�
hiddennum=2; %������ڵ�
type='sig';%sin%hardlim%sig%�����㼤���
TYPE=0;%0=�ع�  1=����
[IW,B,LW,TF,TYPE] = elmtrain(P_train,T_train,hiddennum,type,TYPE);
%% ELM�������
sim = elmpredict(P_test,IW,B,LW,TF,TYPE);
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
title('ELM������ع�Ԥ��')
xlabel('������')
ylabel('PM2.5����')
% ������
figure
plot(abs(test-test_sim)./test)
title('ELM')
ylabel('������')
xlabel('������')
% ƽ��������
pjxd=sum(abs(test-test_sim)./test)/length(test)