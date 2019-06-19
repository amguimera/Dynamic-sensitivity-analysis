%%Dynamic sensitivity analysis in SimBiology -- Local analysis of rate constants%%
%%Developed by Alvaro Martinez Guimera - June 2019%%

%Sensitivty Analysis settings
Timecourse_Duration=20; %Length of time to be simulated
Timepoints=[1 5 10 15 20]; %Timepoints to perform sensitivity analysis at (must be in same units as the model)
Perturbation_Magnitude=0.1; % 10 percent

%Create SimBiology model (once model is made this part of the code (line 11 to 63) can be commenetd out and the model imported by unhashing line 70)


%Define model object
modelObj = sbiomodel ('Model_Name'); %Define model name

%Create compartment
compObj = addcompartment(modelObj, 'cell');

%Create species
speciesObj1 = addspecies (compObj, 'Species1');
speciesObj2 = addspecies (compObj, 'Species2');
speciesObj3 = addspecies (compObj, 'Species3');
speciesObj4 = addspecies (compObj, 'Nil');
% and so on

%Set initial abundances
set (speciesObj1, 'InitialAmount',10);
set (speciesObj2, 'InitialAmount',10);
set (speciesObj3, 'InitialAmount',10);
set (speciesObj4, 'InitialAmount',1); %Empty state to synthesise from or degrade to
% and so on

% Add a kinetic parameters
parameter1 = addparameter(modelObj, 'k1', 0.588783, 'ConstantValue', false);
parameter2 = addparameter(modelObj, 'k2', 0.114598, 'ConstantValue', false);
parameter3 = addparameter(modelObj, 'k3', 0.355184, 'ConstantValue', false);
% and so on

%Add reactions
reaction1 = addreaction(modelObj, 'Species1 + Species2 -> Species1 + Species3'); %Format of a catalysed reaction
reaction2 = addreaction(modelObj, 'Species1 + Species3 + Nil -> Nil'); %Format of a degradation reaction
reaction3 = addreaction(modelObj, 'Nil -> Species1 + Nil'); %Format of a synthesis reaction
% and so on

%Add kinetic Laws
kineticLaw1 = addkineticlaw(reaction1,'MassAction');
kineticLaw2 = addkineticlaw(reaction2,'MassAction');
kineticLaw3 = addkineticlaw(reaction3,'MassAction');
% and so on

%Provide parameter names
kineticLaw1.ParameterVariableNames = 'k1';  %Through the names the kinetic laws can then find the appropriate parameter (scoped to the model)
kineticLaw2.ParameterVariableNames = 'k2';
kineticLaw3.ParameterVariableNames = 'k3';
% and so on

%Add event into simulation (if required)
%event1 = addevent(modelObj,'time>=10','Species1 = 20'); %when 10 time units have passed set Species_1 abundance to 20 units.
% and so on

%Save Model as
sbiosaveproject('File_Name', 'modelObj') %Simbiology project
%sbmlexport(modelObj, 'File_Name')  %SBML file
%}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%If model has already been created and saved then comment out lines 8-58 and
%uncomment model import line 65 below.
%sbioloadproject('File_Name')

%Number of parameters in the model
NumOfParams=numel(modelObj.Parameters);

%Number of events in the model
NumOfEvents=numel(modelObj.Events);

%Perform a 'Control' deterministic simulation to compare sensitivity analysis output to

%Perform deterministic simulation
cs = getconfigset(modelObj,'active');
cs.SolverType = 'ode45';  %ODE solver - ODE45 non-stiff, ODE15s & ODE23 = stiff
cs.SolverOptions.AbsoluteTolerance= 1.0e-12;
cs.SolverOptions.RelativeTolerance= 1.0e-6;
cs.StopTime = Timecourse_Duration; %Simulation stop time
%cs.SolverOptions.LogDecimation = 200;   %how frequently you want to record the output of a stochastic simulation (ex. every 200 ime units)
cs.CompileOptions.UnitConversion = false;  %No unit conversion
Simulation_Output=sbiosimulate(modelObj); %Simulate model
%sbioplot(Simulation_Output);  %plot simulation output

%Extract control data at last timepoint in simulation
Control_Output=Simulation_Output.Data(end,1:end-NumOfParams); %Columns correspond to species in the order they appear in the modelObj. The last column indices corresponding to the
%number of parameters are not included since when parameters are defined as non-constant (so they can be changed by an Event) then they are plotted as variables (even though they
%might remain constant)
      
%Perform dynamic sensitivity analysis            
%
 for TP = 1:numel(Timepoints)
    tic
    Time=Timepoints(TP);
    Time_string=num2str(Time);
    NumOfTimepoints=numel(Timepoints);
    fprintf('Currently performing dynamic sensitivity analysis on timepoint number %d out of %d. \n',TP,NumOfTimepoints);

    Sensitivity_Results=[];
    for P=1:numel(modelObj.Parameters)
        Original_Parameter=modelObj.Parameters(P).Value; %Retrieve original parameter value
        New_Parameter=Original_Parameter+(Original_Parameter*Perturbation_Magnitude); %Calculate new parameter value
        New_Parameter_String=num2str(New_Parameter);
        Parameter_Name=modelObj.Parameters(P).Name;
        Event_Time_String=['time>=' Time_string];
        Event_Parameter_String=[Parameter_Name '=' New_Parameter_String];
        Parameter_Perturbation = addevent(modelObj,Event_Time_String,Event_Parameter_String); %Perturb parameter at specific timepoint through Event

        %Perform deterministic simulation under perturbation conditions
        cs = getconfigset(modelObj,'active');
        cs.SolverType = 'ode45';  %ODE solver - ODE45 non-stiff, ODE15s & ODE23 = stiff
        cs.SolverOptions.AbsoluteTolerance= 1.0e-12;
        cs.SolverOptions.RelativeTolerance= 1.0e-6;
        cs.StopTime = Timecourse_Duration; %Simulation stop time
        %cs.SolverOptions.LogDecimation = 200;   %how frequently you want to record the output of a stochastic simulation (ex. every 200 ime units)
        cs.CompileOptions.UnitConversion = false;  %No unit conversion
        Simulation_Output=sbiosimulate(modelObj); %Simulate model
        %sbioplot(Simulation_Output);  %plot simulation output

        %Extract relevant timepoints (tps) - this is the last timepoint in the simulation
        Perturbed_Output=Simulation_Output.Data(end,1:end-NumOfParams); %Extract data for final timepoint

        %Calculate sensitivities         
        Change_in_Output=(Perturbed_Output - Control_Output);
        Change_in_Parameter =(Original_Parameter*Perturbation_Magnitude);
        Scaled_output_change = Change_in_Output./Control_Output;
        Scaled_parameter_change = Change_in_Parameter/Original_Parameter;
        Scaled_Sensitivities= Scaled_output_change/Scaled_parameter_change;

        %Extract data
        Sensitivity_Results=[Sensitivity_Results; Scaled_Sensitivities];

        %Delete perturbation event
        delete(modelObj.Events(NumOfEvents+1)) 
    end
      
    %Convert results to positive log-transformed scalars
    for el = 1:numel(Sensitivity_Results)
        if Sensitivity_Results(el)<0
            Sensitivity_Results(el) = log10(Sensitivity_Results(el)*-1); %Convert all sensitivities to postive values
        elseif Sensitivity_Results(el)>0
            Sensitivity_Results(el) = log10(Sensitivity_Results(el));
        elseif Sensitivity_Results(el)==0
            Sensitivity_Results(el)=Sensitivity_Results(el);
        elseif isnan(Sensitivity_Results(el))==1
            Sensitivity_Results(el)=0;
        end
    end
    
    %Invert results matrix so that the parameters are on the x-axis (since there tends to me more parameters than species in models)
    Sensitivity_Results=Sensitivity_Results';  
    
    %Create heatmaps
    
    %Create string list of species names
    SpeciesNames={};
    ParameterNames={};
    for i=1:numel(Simulation_Output.DataNames)
        Name=cell2mat(Simulation_Output.DataNames(i));
        if i<=(numel(Simulation_Output.DataNames)-NumOfParams)
            SpeciesNames{end+1}=Name;
        else
            ParameterNames{end+1}=Name;
        end
    end
        
    %Create xticks and yticks vectors for figures
    xtks=1:numel(ParameterNames);
    ytks=1:numel(SpeciesNames);
    
    %Create Figures   
    figure(TP)
    imagesc(Sensitivity_Results)
    %caxis([-10 10])   %colourjet mapping to data
    xticks(xtks)
    xticklabels(ParameterNames)
    xtickangle(45)
    yticks(ytks)
    yticklabels(SpeciesNames)
    set(gca,'FontWeight','bold','fontsize',30)
    colorbar
    colormap(jet)
    
    %Save data and Figures
    filename = ['Sensitivity_Timepoint_', int2str(Time), '.xlsx'];
    xlswrite(filename,Sensitivity_Results,1);
    h=figure(TP);
    savefig(['Sensitivity_Timepoint_' num2str(Time)])

    toc      
 end


 