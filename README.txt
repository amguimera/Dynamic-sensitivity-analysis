-The user needs to define the sensitivity analysis settings in lines 5 to 7. Other changes can be done as described below (but not exclusively).

-Sensitivities are saved as an excel file containing raw data and a .fig (opens in matlab) containing the figure.

-Script includes lines for the formalisation of a small model (lines 12-62) to guide users that have never defined a model in simbiology before.
Once the user model has been made an saved as a simbiology project (line 61), this part can be commented out and the model imported (uncomment line 70).
Note that the user's model can also be saved in SBML (line 62). Although note that COPASI and Simbiology often do not work well together. Worth 
of note is that MATLAB does not use an empty space to denote a synthesis or degradation of a molecule, a dummy variable must be used instead. 
For example, instead of 'Species1 -> ' in COPASI it would have to be defined as 'Species1 + Nil -> Nil' where Nil is a dummy species that must be defined
with the other model species. A synthesis reaction in Simbiology would thus be: 'Nil -> Species1 + Nil'. Notice that the 'Nil' dummy variable is
used as a modifier so that its value can be conserved at 1 a.u (must be defined at species initial abundance) so that in practice it is just a 
constant multiplier which does not change the rate of the reactions it is written into.

-To visualise the simulation of the developed simbiology model, uncomment line 89 (and comment out the rest of the following code in the script). This
will be useful to make sure that the model has been well defined. It should match the simulation profiles in the corresponding COPASI model.

-To speed up the program you can change the ode45 solver to ode15s or other (lines 82 & 117) although note that this will theoretically limit the resolution 
into the sensitivities. On a university computer the program takes 5 min per timepoint to calculate the sensitivities of a model the size that published
by Dalle Pezze et al. (2014) -41 parameters and 26 species- when using the ode45 solver. This time is reduced to 15 seconds when using the ode15s solver.

-If species or rate constants are named with underscores (ex. AMPK_catalysis or AMPK_Phospho) MATLAB interprets this as making the letter after 
the underscore a subscript, and will plot it as such. This might be useful to know for chemical formulas. I think Simbiology does not like the
names to contains dashes either (ex. AMPK-catalysis or AMPK-Phospho).

-To change font size of heatmap labels use line 186 although this can be also changed by opening the saved .fig image and opening the property editor.

-To change heatmap colormap use line 188 (see matlab documentation for other colormaps).This can be also changed by opening the saved .fig image and 
opening the property editor.

-To change the name of the files being saved or uncommenting them see lines 191-194.

-Figures are saved as .fig files to be subsequently opened in MATLAB, edited as appropriate and then saved in any other desired format.

-Because there can be a large difference in the effect on simlulation output by parameter perturbations, the data is log transformed (line 141-149).

-Note that sensitivities are transformed so that they are all positive (lines 144-154) so this assumes the direction of the change in simulation output
relative to the reference simulation is not important.

-The changes in simulation output as a result of perturbation are taken from the final timepoint in the simulation. This is because this
timepoint encodes cumulative changes.

-To increase heatmap resolution (at the expense of losing it in the visualisation of "outliers") use line 180 to modify the mapping of colour
 to values.
 
-The script is made so that the parameter perturbation is made on top of an original paramater value so that the new parameter value corresponds to
NewParameter = OldParameter + Perturbation. This can be changed so that the perturbation to the parameter value goes in the other direction:
NewParameter = OldParameter - Perturbation by changing the plus sign into a minus sign on line 108. This is in case the effect or parameter perturbations 
on the resulting sensitivities is assymetrical.

-If you type simbiology in the matlab command window you will be able to manage the model through a GUI once you open it.

All the best, 
Alvaro