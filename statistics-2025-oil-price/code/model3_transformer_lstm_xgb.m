clc;clear;close all;	
load('MT_24_Apr_2025_02_30_09.mat')	
random_seed=G_out_data.random_seed;	
rng(random_seed)	
	
data_str=G_out_data.data_path_str ;  %读取数据的路径 	
dataO1=readtable(data_str,'VariableNamingRule','preserve'); %读取数据 	
data1=dataO1(:,2:end);test_data=table2cell(dataO1(1,2:end));	
for i=1:length(test_data)	
      if ischar(test_data{1,i})==1	
          index_la(i)=1;     %char类型	
      elseif isnumeric(test_data{1,i})==1	
          index_la(i)=2;     %double类型	
      else	
        index_la(i)=0;     %其他类型	
    end 	
end	
index_char=find(index_la==1);index_double=find(index_la==2);	
	
%%数值类型数据处理	
if length(index_double)>=1	
     data_numshuju=table2array(data1(:,index_double));	
     data_numshuju2=data_numshuju;	
     index_need_last=index_double;	
else	
     index_need_last=index_double;	
    data_numshuju2=[];	
end	
	
% 文本类型数据处理	
data_shuju=[];	
if length(index_char)>=1	
   for j=1:length(index_char)	
     data_get=table2array(data1(:,index_char(j)));	
	
     data_label=unique(data_get);	
     for NN=1:length(data_label)	
         idx = find(ismember(data_get,data_label{NN,1}));	
         data_shuju(idx,j)=NN;	
     end	
   end	
end	
data_all_last=[data_shuju,data_numshuju2];	
label_all_last=[index_char,index_need_last];	
data=data_all_last;	
     data_biao_all=data1.Properties.VariableNames;	
for j=1:length(label_all_last)	
     data_biao{1,j}=data_biao_all{1,label_all_last(j)};	
end	
	
	
	
	
data_numshuju=data;	
for NN=1:size(data_numshuju,2)	
      data_test=data_numshuju(:,NN);	
      index=isnan(data_test);	
      data_test1=data_test;	
      data_test1(index)=[];	
      index_label=1:length(data_test);	
      index_label1=index_label;	
      index_label1(index)=[];	
     data_all=interp1(index_label1,data_test1,index_label,'spline');	
	
     dataO(:,NN)=data_all;	
end	
	
A_data1=dataO;	
data_biao1=data_biao;	
select_feature_num=G_out_data.select_feature_num;   %特征选择的个数	
predict_num=G_out_data.predict_num_set;   %预测的点个数	
	
data_select=A_data1;	
feature_need_last=1:size(A_data1,2)-predict_num;	
	
data_select1=data_select;	
data_select1=data_select1;	
	
	
	
%%波形分解	
data_select1_cell=[];	
data_select1_cell{1,1}=data_select1;	
	
	
 % 模型训练参数	
select_predict_num=G_out_data.select_predict_num;  %待预测数	
num_feature=G_out_data.num_feature;    %特征选择量	
num_series=G_out_data.num_series;     %序列选择	
num_input_serise=num_series;     	
min_batchsize=G_out_data.min_batchsize; 	
roll_num=G_out_data.roll_num;    %滚动次数	
roll_num_in=G_out_data.roll_num_in;	
num_pop=G_out_data.num_pop;  %优化种群数	
num_iter=G_out_data.num_iter;  %优化迭代数	
num_BO_iter=G_out_data.num_BO_iter;  %贝叶斯优化迭代次数	
max_epoch_LC=G_out_data.max_epoch_LC; %最大轮数	
method_mti=G_out_data.method_mti; %最大轮数	
list_cell=	G_out_data.list_cell;	
	
attention_label=G_out_data.attention_label;	
attention_head=G_out_data.attention_head;	
	
%% 模型训练	
x_mu_all=[];x_sig_all=[];y_mu_all=[];y_sig_all=[];  	
for NUM_all=1:length(data_select1_cell)	
    data_process=data_select1_cell{1,NUM_all};	
   [x_feature_label,y_feature_label]=timeseries_process2(data_process,select_predict_num,num_series); 	
   [~,y_feature_label1]=timeseries_process2(data_select1,select_predict_num,num_series);    %未分解之前	
	
	
	
  index_label1=1:(size(x_feature_label,1)); index_label=index_label1;	
  spilt_ri=G_out_data.spilt_ri;	
  train_num=round(spilt_ri(1)/(sum(spilt_ri))*size(x_feature_label,1));                    %训练集个数	
  vaild_num=round((spilt_ri(1)+spilt_ri(2))/(sum(spilt_ri))*size(x_feature_label,1)); %验证集个数	
  %训练集，验证集，测试集	
  train_x_feature_label=x_feature_label(index_label(1:train_num),:);	
  train_y_feature_label=y_feature_label(index_label(1:train_num),:);	
  vaild_x_feature_label=x_feature_label(index_label(train_num+1:vaild_num),:);	
  vaild_y_feature_label=y_feature_label(index_label(train_num+1:vaild_num),:);	
  test_x_feature_label=x_feature_label(index_label(vaild_num+1:end),:);	
  test_y_feature_label=y_feature_label(index_label(vaild_num+1:end),:);	
  %Zscore 标准化	
	
  %训练集	
  x_mu = mean(train_x_feature_label);  x_sig = std(train_x_feature_label); 	
  train_x_feature_label_norm = (train_x_feature_label - x_mu) ./ x_sig;    % 训练数据标准化	
  y_mu = mean(train_y_feature_label);  y_sig = std(train_y_feature_label); 	
  train_y_feature_label_norm = (train_y_feature_label - y_mu) ./ y_sig;    % 训练数据标准化	
  x_mu_all(NUM_all,:)=x_mu;x_sig_all(NUM_all,:)=x_sig;y_mu_all(NUM_all,:)=y_mu;y_sig_all(NUM_all,:)=y_sig;                   	
  %验证集	
  vaild_x_feature_label_norm = (vaild_x_feature_label - x_mu) ./ x_sig;    % 训练数据标准化	
  vaild_y_feature_label_norm = (vaild_y_feature_label - y_mu) ./ y_sig;    % 训练数据标准化	
  %测试集	
  test_x_feature_label_norm = (test_x_feature_label - x_mu) ./ x_sig;    % 训练数据标准化	
  test_y_feature_label_norm = (test_y_feature_label - y_mu) ./ y_sig;    % 训练数据标准化	
	
	
	
	
y_train_predict_norm=zeros(size(train_y_feature_label,1),size(train_y_feature_label,2));y_vaild_predict_norm=zeros(size(vaild_y_feature_label,1),size(vaild_y_feature_label,2));	
y_test_predict_norm=zeros(size(test_y_feature_label,1),size(test_y_feature_label,2));	
	
  for N1=1:length(list_cell)	
    hidden_size=G_out_data.hidden_size;	
    p_train1=cell(size(train_x_feature_label,1),1);p_test1=cell(size(test_x_feature_label,1),1);p_vaild1=cell(size(vaild_x_feature_label,1),1);	
    O_train1=cell(size(train_x_feature_label,1),1);O_test1=cell(size(test_x_feature_label,1),1);O_vaild1=cell(size(vaild_x_feature_label,1),1);	
    for i = 1: size(train_x_feature_label,1)      %修改输入变成元胞形式	
          p_train1{i, 1} = (train_x_feature_label_norm(i,:))';	
   end	
   for i = 1 : size(test_x_feature_label,1)	
        p_test1{i, 1}  = (test_x_feature_label_norm(i,:))';	
   end	
   for i = 1 : size(vaild_x_feature_label,1)	
        p_vaild1{i, 1}  = (vaild_x_feature_label_norm(i,:))';	
   end	
	
   for i = 1: size(train_x_feature_label,1)      %修改输入变成元胞形式	
      O_train1{i, 1} = (train_y_feature_label_norm(i,list_cell{1,N1}))';	
   end  	
   for i = 1 : size(test_x_feature_label,1)	
       O_test1{i, 1}  = (test_y_feature_label_norm(i,list_cell{1,N1}))';	
   end	
    for i = 1 : size(vaild_x_feature_label,1)	
       O_vaild1{i, 1}  = (vaild_y_feature_label_norm(i,list_cell{1,N1}))';	
    end	
	
	
	
    [Mdl,~,fitness,Loss] = optimize_fitrTrans_LSTMS1(p_train1,O_train1,p_vaild1,O_vaild1,num_pop,num_iter,method_mti,max_epoch_LC,min_batchsize,1); 	
	
    y_train_predict_norm1 = predict(Mdl, p_train1,'MiniBatchSize',min_batchsize);	
    y_vaild_predict_norm1 = predict(Mdl, p_vaild1,'MiniBatchSize',min_batchsize);	
    y_test_predict_norm1 =  predict(Mdl, p_test1,'MiniBatchSize',min_batchsize);	
	
 y_train_predict_norm_roll=[];y_vaild_predict_norm_roll=[];y_test_predict_norm_roll=[];	
  for i=1:length(y_train_predict_norm1)	
          y_train_predict_norm_roll(i,:) = (y_train_predict_norm1{i,1}); 	
 end	
   for i=1:length(y_vaild_predict_norm1)	
        y_vaild_predict_norm_roll(i,:) = (y_vaild_predict_norm1{i,1});	
    end	
	
   for i=1:length(y_test_predict_norm1) 	
         y_test_predict_norm_roll(i,:) = (y_test_predict_norm1{i,1});  	
  end 	
 y_train_predict_norm(:,list_cell{1,N1})=y_train_predict_norm_roll; 	
 y_vaild_predict_norm(:,list_cell{1,N1})=y_vaild_predict_norm_roll; 	
 y_test_predict_norm(:,list_cell{1,N1})=y_test_predict_norm_roll; 	
 Model{1,N1}=Mdl; 	
Model_Transformer_LSTM{1,N1}=Mdl; 	
 model_all{NUM_all,N1}=Mdl; 	
 graph = layerGraph(Mdl.Layers); figure; plot(graph) 	
 end	
 y_train_predict_cell_Transformer_LSTM{1,NUM_all}=y_train_predict_norm.*y_sig+y_mu;  %反标准化操作	
 y_vaild_predict_cell_Transformer_LSTM{1,NUM_all}=y_vaild_predict_norm.*y_sig+y_mu;	
 y_test_predict_cell_Transformer_LSTM{1,NUM_all}=y_test_predict_norm.*y_sig+y_mu;	
	
y_train_predict_norm=zeros(size(train_y_feature_label,1),size(train_y_feature_label,2));y_vaild_predict_norm=zeros(size(vaild_y_feature_label,1),size(vaild_y_feature_label,2));	
y_test_predict_norm=zeros(size(test_y_feature_label,1),size(test_y_feature_label,2));	
Model_XGB=cell(1,select_predict_num);	
	
 for NN1=1:select_predict_num  	
	
   if NN1==select_predict_num  	
    [Mdl,fitness] = optimize_fitrtrXGB1(train_x_feature_label_norm,train_y_feature_label_norm(:,list_cell{1,N1}(NN1)),vaild_x_feature_label_norm,vaild_y_feature_label_norm(:,list_cell{1,N1}(NN1)),num_pop,num_iter,method_mti,1);     	
  else  	
    [Mdl,fitness] = optimize_fitrtrXGB1(train_x_feature_label_norm,train_y_feature_label_norm(:,list_cell{1,N1}(NN1)),vaild_x_feature_label_norm,vaild_y_feature_label_norm(:,list_cell{1,N1}(NN1)),num_pop,num_iter,method_mti,0);       	
  end 	
	
       y_train_predict_norm(:,NN1)=predict_xgb(Mdl,train_x_feature_label_norm);  	
       y_vaild_predict_norm(:,NN1)=predict_xgb(Mdl,vaild_x_feature_label_norm);  	
       y_test_predict_norm(:,NN1)=predict_xgb(Mdl,test_x_feature_label_norm); 	
       Model_XGB{1,NN1}=Mdl;  	
       Mdl_all{2,NN1}=Mdl;  	
       model_all{NUM_all+length(data_select1_cell),NN1}=Mdl; 	
 end 	
   	
 y_train_predict_cell_XGB{1,NUM_all}=y_train_predict_norm.*y_sig+y_mu;  %反标准化操作  	
 y_vaild_predict_cell_XGB{1,NUM_all}=y_vaild_predict_norm.*y_sig+y_mu;  	
 y_test_predict_cell_XGB{1,NUM_all}=y_test_predict_norm.*y_sig+y_mu;   	
   	
   	
figure	
subplot(2, 1, 1)	
plot(1 : length(Loss.TrainingRMSE), Loss.TrainingRMSE, '-', 'LineWidth', 1)	
xlabel('迭代次数');ylabel('均方根误差');legend('训练集均方根误差');title ('训练集均方根误差曲线');grid;set(gcf,'color','w')	
subplot(2, 1, 2)	
plot(1 : length(Loss.TrainingLoss), Loss.TrainingLoss, '-', 'LineWidth', 1)	
xlabel('迭代次数');ylabel('损失函数');legend('训练集损失值');title ('训练集损失函数曲线');grid;set(gcf,'color','w')	
	
	
	
	
y_train_predict_cell{1,NUM_all}=y_train_predict_norm.*y_sig+y_mu;  %反标准化操作	
y_vaild_predict_cell{1,NUM_all}=y_vaild_predict_norm.*y_sig+y_mu;	
 y_test_predict_cell{1,NUM_all}=y_test_predict_norm.*y_sig+y_mu;	
	
end	
	
	
	
y_train_predict_Transformer_LSTM=0;y_vaild_predict_Transformer_LSTM=0;y_test_predict_Transformer_LSTM=0;	
y_train_predict_XGB=0;y_vaild_predict_XGB=0;y_test_predict_XGB=0;	
for i=1:length(data_select1_cell)	
      y_train_predict_Transformer_LSTM=y_train_predict_Transformer_LSTM+ y_train_predict_cell_Transformer_LSTM{1,i};	
      y_vaild_predict_Transformer_LSTM=y_vaild_predict_Transformer_LSTM+ y_vaild_predict_cell_Transformer_LSTM{1,i};	
      y_test_predict_Transformer_LSTM=y_test_predict_Transformer_LSTM+ y_test_predict_cell_Transformer_LSTM{1,i};	
	
      y_train_predict_XGB=y_train_predict_XGB+ y_train_predict_cell_XGB{1,i};	
      y_vaild_predict_XGB=y_vaild_predict_XGB+ y_vaild_predict_cell_XGB{1,i};	
    y_test_predict_XGB=y_test_predict_XGB+ y_test_predict_cell_XGB{1,i};	
end	
	
    vaild_y=vaild_y_feature_label;	
    vaild_MAE_Transformer_LSTM=sum((abs(y_vaild_predict_Transformer_LSTM-vaild_y)))/size(vaild_y,1) ; disp(['Transformer_LSTM验证集平均绝对误差MAE：',num2str(vaild_MAE_Transformer_LSTM)])	
    vaild_MAE_XGB=sum((abs(y_vaild_predict_XGB-vaild_y)))/size(vaild_y,1) ; disp(['XGB验证集平均绝对误差MAE：',num2str(vaild_MAE_XGB)])	
	
for N1=1:length(vaild_MAE_XGB)	
    errors_XGB=vaild_MAE_XGB(N1);	
    errors_Transformer_LSTM=vaild_MAE_Transformer_LSTM(N1);	
    if abs((errors_Transformer_LSTM-errors_XGB)/max(errors_Transformer_LSTM,errors_XGB))<0.1	
       quan1=errors_XGB/(errors_Transformer_LSTM+errors_XGB);quan2=errors_Transformer_LSTM/(errors_Transformer_LSTM+errors_XGB);	
     else	
            if(errors_Transformer_LSTM>errors_XGB)	
            quan1=0;quan2=1;    	
            else	
            quan1=1;quan2=0;	
            end	
    end	
         Mdl_all{3,1}(N1,:)=[quan1,quan2];	
end	
	
y_train_predict=[];y_vaild_predict=[];y_test_predict=[];	
for N=1:length(vaild_MAE_XGB)	
    quan=Mdl_all{3,1}(N,:);	
    y_train_predict(:,N)=y_train_predict_Transformer_LSTM(:,N)*quan(1)+y_train_predict_XGB(:,N)*quan(2);	
    y_vaild_predict(:,N)=y_vaild_predict_Transformer_LSTM(:,N)*quan(1)+y_vaild_predict_XGB(:,N)*quan(2);	
    y_test_predict(:,N)=y_test_predict_Transformer_LSTM(:,N)*quan(1)+y_test_predict_XGB(:,N)*quan(2);	
end	
	
train_y_feature_label=y_feature_label1(index_label(1:train_num),:); 	
vaild_y_feature_label=y_feature_label1(index_label(train_num+1:vaild_num),:);	
test_y_feature_label=y_feature_label1(index_label(vaild_num+1:end),:);	
	
disp('************************************************************************************')	
disp('Transformer_LSTM-XGB预测')	
train_y=train_y_feature_label; 	
train_MAE=sum(sum(abs(y_train_predict-train_y)))/size(train_y,1)/size(train_y,2) ; disp(['Transformer_LSTM-XGB训练集平均绝对误差MAE：',num2str(train_MAE)])	
train_MAPE=sum(sum(abs((y_train_predict-train_y)./train_y)))/size(train_y,1)/size(train_y,2); disp(['Transformer_LSTM-XGB训练集平均相对误差MAPE：',num2str(train_MAPE)])	
train_MSE=(sum(sum(((y_train_predict-train_y)).^2))/size(train_y,1)/size(train_y,2)); disp(['Transformer_LSTM-XGB训练集均方根误差MSE：',num2str(train_MSE)])    	
train_RMSE=sqrt(sum(sum(((y_train_predict-train_y)).^2))/size(train_y,1)/size(train_y,2)); disp(['Transformer_LSTM-XGB训练集均方根误差RMSE：',num2str(train_RMSE)]) 	
train_R2 = 1 - mean(norm(train_y - y_train_predict)^2 / norm(train_y - mean(train_y))^2);   disp(['Transformer_LSTM-XGB训练集均方根误差R2：',num2str(train_R2)]) 	
disp('************************************************************************************')	
vaild_y=vaild_y_feature_label;	
vaild_MAE=sum(sum(abs(y_vaild_predict-vaild_y)))/size(vaild_y,1)/size(vaild_y,2) ; disp(['Transformer_LSTM-XGB验证集平均绝对误差MAE：',num2str(vaild_MAE)])	
vaild_MAPE=sum(sum(abs((y_vaild_predict-vaild_y)./vaild_y)))/size(vaild_y,1)/size(vaild_y,2); disp(['Transformer_LSTM-XGB验证集平均相对误差MAPE：',num2str(vaild_MAPE)])	
vaild_MSE=(sum(sum(((y_vaild_predict-vaild_y)).^2))/size(vaild_y,1)/size(vaild_y,2)); disp(['Transformer_LSTM-XGB验证集均方根误差MSE：',num2str(vaild_MSE)])     	
vaild_RMSE=sqrt(sum(sum(((y_vaild_predict-vaild_y)).^2))/size(vaild_y,1)/size(vaild_y,2)); disp(['Transformer_LSTM-XGB验证集均方根误差RMSE：',num2str(vaild_RMSE)]) 	
vaild_R2 = 1 - mean(norm(vaild_y - y_vaild_predict)^2 / norm(vaild_y - mean(vaild_y))^2);   disp(['Transformer_LSTM-XGB验证集均方根误差R2：',num2str(vaild_R2)]) 	
disp('************************************************************************************')	
test_y=test_y_feature_label;	
test_MAE_Transformer_LSTM=sum(sum(abs(y_test_predict_Transformer_LSTM-test_y)))/size(test_y,1)/size(test_y,2) ; disp(['Transformer_LSTM测试集平均绝对误差MAE：',num2str(test_MAE_Transformer_LSTM)])	
test_MAE_XGB=sum(sum(abs(y_test_predict_XGB-test_y)))/size(test_y,1)/size(test_y,2) ; disp(['XGB测试集平均绝对误差MAE：',num2str(test_MAE_XGB)])	
test_MAE=sum(sum(abs(y_test_predict-test_y)))/size(test_y,1)/size(test_y,2) ; disp(['Transformer_LSTM-XGB测试集平均绝对误差MAE：',num2str(test_MAE)])	
test_MAPE=sum(sum(abs((y_test_predict-test_y)./test_y)))/size(test_y,1)/size(test_y,2); disp(['Transformer_LSTM-XGB测试集平均相对误差MAPE：',num2str(test_MAPE)])	
test_MSE=(sum(sum(((y_test_predict-test_y)).^2))/size(test_y,1)/size(test_y,2)); disp(['Transformer_LSTM-XGB测试集均方根误差MSE：',num2str(test_MSE)]) 	
test_RMSE=sqrt(sum(sum(((y_test_predict-test_y)).^2))/size(test_y,1)/size(test_y,2)); disp(['Transformer_LSTM-XGB测试集均方根误差RMSE：',num2str(test_RMSE)]) 	
test_R2 = 1 - mean(norm(test_y - y_test_predict)^2 / norm(test_y - mean(test_y))^2);   disp(['Transformer_LSTM-XGB测试集均方根误差R2：',num2str(test_R2)]) 	
	
model_all{length(data_select1_cell)*3,1}=Mdl_all{3,1};	
	
	
	
%% 调用模型得到数据预测结果	
	
y_last_predict_cell=cell(1,length(data_select1_cell));	
for NUM_all=1:length(data_select1_cell)	
      data_process=data_select1_cell{1,NUM_all};	
      data_process=data_process(vaild_num+1:end,:);	
	
       [x_feature_label]=timeseries_process2_Pre(data_process,select_predict_num,num_series);	
	
       x_mu=x_mu_all(NUM_all,:);	
       x_sig=x_sig_all(NUM_all,:);	
       pre_x_feature_label_norm = (x_feature_label - x_mu) ./ x_sig;    % 训练数据标准化	
	
       for i = 1: size(pre_x_feature_label_norm,1)      %修改输入变成元胞形式	
           p_pre1{i, 1} = (pre_x_feature_label_norm(i,:))';	
       end	
       for N1=1:length(list_cell)	
            Mdl=model_all{NUM_all,N1};	
            y_pre_predict_norm1 =  predict(Mdl, p_pre1,'MiniBatchSize',min_batchsize);	
            y_pre_predict_norm1_roll=[];	
          for i=1:length(y_pre_predict_norm1)	
            y_pre_predict_norm1_roll(i,:) = (y_pre_predict_norm1{i,1});  	
          end	
         y_pre_predict_norm(:,list_cell{1,N1})=y_pre_predict_norm1_roll;	
       end	
       y_pre_predict_cell_LSTM{1,NUM_all}=y_pre_predict_norm;	
	
      for NN1=1:select_predict_num	
         Mdl=model_all{NUM_all+length(data_select1_cell),NN1};	
         y_pre_predict_norm1 =  predict_xgb(Mdl, pre_x_feature_label_norm);	
         y_pre_predict_norm(:,NN1)=y_pre_predict_norm1; 	
     end	
      y_pre_predict_cell_XGB{1,NUM_all}=y_pre_predict_norm;  %反标准化操作 	
      quan1=model_all{length(data_select1_cell)*3,1};	
      for N=1:size(y_pre_predict_norm,2) 	
          quan=quan1(N,:);	
          y_pre_predict_norm(:,N)=y_pre_predict_cell_LSTM{1,NUM_all}(:,N)*quan(1)+y_pre_predict_cell_XGB{1,NUM_all}(:,N)*quan(2);	
     end	
    	
        y_last_predict_cell{1,NUM_all}=y_pre_predict_norm.*y_sig_all(NUM_all,:)+y_mu_all(NUM_all,:);  %反标准化操作	
    end	
	
y_last_predict=0;   y_before=0;	
for i=1:length(data_select1_cell)	
      y_last_predict=y_last_predict+ y_last_predict_cell{1,i};	
      y_before=y_before+data_select1_cell{1,i}(vaild_num+1:end,end);	
end	
	
y_last_predict1=y_last_predict(end,1:end);	
disp('预测未来时间点数据为:')	
	
disp(y_last_predict1)	
figure;	
plot([1:length(y_before)],y_before,'-o','LineWidth',1);		
hold on	
plot([length(y_before)+1:length(y_before)+length(y_last_predict1)],y_last_predict1,'-p','LineWidth',1.2)		
hold on	
legend('True','Predict')	
set(gca,'LineWidth',1.2)	
	
show_wei_num=G_out_data.show_wei_num; %展示输出的维度	
train_y1=train_y(:,show_wei_num);	
vaild_y1=vaild_y(:,show_wei_num);	
test_y1=test_y(:,show_wei_num);	
	
y_train_predict1=y_train_predict(:,show_wei_num);	
y_vaild_predict1=y_vaild_predict(:,show_wei_num);	
y_test_predict1=y_test_predict(:,show_wei_num);	
	
color_list=G_out_data.color_list; 	
Line_Width=G_out_data.Line_Width;	
rand_list1=G_out_data.rand_list1;	
makesize=G_out_data.makesize;	
color_index=G_out_data.color_index;	
show_num1=G_out_data.show_num1;	
show_num2=G_out_data.show_num2;	
show_num3=G_out_data.show_num3;	
yang_str2=G_out_data.yang_str2;	
yang_str3=G_out_data.yang_str3;	
yangsi_idnex=G_out_data.yangsi_idnex;	
yang_fu3_ku=G_out_data.yang_fu3_ku;	
if show_num1>length(train_y1)	
    show_num1=length(train_y1);	
end	
index_show=1:show_num1;	
figure_density(color_index,y_train_predict1,train_y1,'训练集')	
figure('Position',[200,200,600,350]);	
XX=1:length(train_y1);	
plot(gca,XX(index_show),train_y1(index_show),yang_str2{1,3},'Color',color_list(rand_list1(1),:),'LineWidth',Line_Width(1))	
hold (gca,'on')	
plot(gca, XX(index_show),y_train_predict1(index_show),yang_str3{1,1},'Color',color_list(rand_list1(2),:),'LineWidth',Line_Width(1),'MarkerSize',makesize)	
hold (gca,'on')	
title('训练集测试效果')	
	
FontName=G_out_data.FontName;	
FontSize=G_out_data.FontSize;	
kuang_width=G_out_data.kuang_width;	
 set(gca,'FontName',FontName,'FontSize',FontSize,'LineWidth',kuang_width)	
	
xlabel1=G_out_data.xlabel1;	
ylabel1=G_out_data.ylabel1;	
legend1=G_out_data.legend1;	
 xlabel(xlabel1)	
ylabel(ylabel1)	
legend(legend1)	
	
box1=G_out_data.box1;	
box(gca,box1) 	
le_kuang=G_out_data.le_kuang;	
 legend(gca,le_kuang) %图例框消失	
grid1=G_out_data.grid1;	
grid(gca,grid1)	
	
if show_num2>length(test_y1)	
   show_num2=length(test_y1);	
end	
	
index_show=1:show_num2;	
figure_density(color_index,y_test_predict1,test_y1,'测试集')	
figure('Position',[200,200,600,350]);	
XX=1:length(test_y1);	
plot(gca,XX(index_show),test_y1(index_show),yang_str2{1,3},'Color',color_list(rand_list1(1),:),'LineWidth',Line_Width(1))	
hold (gca,'on')	
plot(gca, XX(index_show),y_test_predict1(index_show),yang_str3{1,1},'Color',color_list(rand_list1(2),:),'LineWidth',Line_Width(1),'MarkerSize',makesize)	
hold (gca,'on')	
 title('测试集测试效果')	
	
 set(gca,'FontName',FontName,'FontSize',FontSize,'LineWidth',kuang_width)	
	
xlabel(xlabel1)	
ylabel(ylabel1)	
legend(legend1)	
	
 box(gca,box1) 	
 legend(gca,le_kuang) %图例框消失	
grid(gca,grid1)	
	
 if show_num3>length(vaild_y1)	
     show_num3=length(vaild_y1);	
end	
index_show=1:show_num3;	
figure_density(color_index,y_vaild_predict1,vaild_y1,'验证集')	
figure('Position',[200,200,600,350]);	
XX=1:length(vaild_y1);	
plot(gca,XX(index_show),vaild_y1(index_show),yang_str2{1,3},'Color',color_list(rand_list1(1),:),'LineWidth',Line_Width(1))	
hold (gca,'on')	
plot(gca, XX(index_show),y_vaild_predict1(index_show),yang_str3{1,1},'Color',color_list(rand_list1(2),:),'LineWidth',Line_Width(1),'MarkerSize',makesize)	
hold (gca,'on')	
title('验证集测试效果')	
	
set(gca,'FontName',FontName,'FontSize',FontSize,'LineWidth',kuang_width)	
	
xlabel(xlabel1)	
ylabel(ylabel1)	
legend(legend1)	
	
box(gca,box1) 	
legend(gca,le_kuang) %图例框消失	
grid(gca,grid1)	
	
	
	
figure		
fu_str4=G_out_data.fu_str4;	
rand_list4=G_out_data.rand_list4;	
	
data_get=[train_y1,y_train_predict1];   	
hh(1)=scatter(data_get(:,1),data_get(:,2),makesize*10,'filled','CData',color_list(rand_list4(1),:),'LineWidth',Line_Width(1),'Marker',fu_str4{1,1}); hold on;   	
data_get1=[test_y1,y_test_predict1];   	
hh(2)=scatter(data_get1(:,1),data_get1(:,2),makesize*10,'filled','CData',color_list(rand_list4(2),:),'LineWidth',Line_Width(1),'Marker',fu_str4{1,2}); hold on;   	
   	
lm1 = fitlm(train_y1, y_train_predict1);    % 获取 R^2 系数 	
[y_pred1, y_ci1] = predict(lm1, train_y1);   	
R2_train = lm1.Rsquared.Ordinary; %R2系数   	
[sorted_x, sortIdx] = sort(train_y1);   	
   	
h1(1)=fill(gca,[train_y1(sortIdx)',fliplr(train_y1(sortIdx)')],[y_ci1(sortIdx,1)',fliplr(y_ci1(sortIdx,2)')],color_list(rand_list4(1),:),'EdgeColor',[1,1,1],'FaceAlpha', 0.3);hold on   	
h2(1)=plot(train_y1,y_pred1,'Color',color_list(rand_list4(1),:)); hold on   	
   	
lm2 = fitlm(test_y1, y_test_predict1);   	
R2_test = lm2.Rsquared.Ordinary; %R2系数   	
[y_pred2, y_ci2] = predict(lm2, test_y1);   	
[sorted_x1, sortIdx1] = sort(test_y1);   	
h1(2)=fill(gca,[test_y1(sortIdx1)',fliplr(test_y1(sortIdx1)')],[y_ci2(sortIdx1,1)',fliplr(y_ci2(sortIdx1,2)')],color_list(rand_list4(2),:),'EdgeColor',[1,1,1],'FaceAlpha', 0.3);hold on   	
h2(2)=plot(test_y1,y_pred2,'Color',color_list(rand_list4(2),:));hold on   	
txt_set = [ newline 'Train: R^2 = ',num2str(R2_train)...   	
     newline 'Test: R^2 = ',num2str(R2_test)];   	
   	
text(min(train_y1)+0.05*(max(train_y1)-min(train_y1)),max(y_train_predict1)-0.1*(max(y_train_predict1)-min(y_train_predict1)),txt_set,  'color','k','FontName',' Times New Roman','FontSize', 11)   	
xlabel('ture');ylabel('predict')   	
set(gca,'FontName',' Times New Roman','FontSize', 12)   	
for i=1:2   	
     Phdl1(i)=PlotDensHist1( hh(i));hold on        	
     Phdl1(i).plotDensHist1();hold on      	
end   	
legend([hh,h1,h2],{'train true','test true','train 95% conf. bounds','test 95% conf. bounds','train regerss fit','test regerss fit'},'EdgeColor',[0.8,0.8,0.8],'FontSize',11,'FontName','Times New Roman','Location','southeast');   	
