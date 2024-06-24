# Cooperative Classification of Prolonged Movement from EEG for BCI without Feedback
This repository contains the code used to recognise sequence of sub-gestures as well as complex fine movements (sub-gestures) from EEG-based continuous motor movement using the approach proposed in [1].

The code provided here was tested on MATLAB2022b and makes use of the MVGC v1.3 Toolbox  [2] for the calculation of the Granger causality measures.


# Citation
**Please cite this repository as:**

Falcon-Caro, A., Ferreira, J. F. & Sanei, S. (2024). Cooperative Classification of Prolonged Movement from EEG for BCI without Feedback.

This resource is released under a MIT License.

---

## Abstract
This paper presents a novel approach for the recognition of a prolonged motor movement from a subject’s electroencephalogram (EEG) using orthogonal functions to model a sequence of sub-gestures. In this approach, the individual’s EEG signals corresponding to physical (or imagery) continuous movement for different gestures are divided into segments associated with their related sub-gestures. Then, a diffusion adaptation approach is introduced to model the interface between the brain neural activity and the corresponding gesture dynamics. In such a formulation, orthogonal Bessel functions are utilized to represent different gestures and used as the target for the adaptation algorithm. This method aims at detecting and evaluating the prolonged motor movements as well as identifying highly complex sub-gestures. This technique can perform satisfactory classification even in the presence of small data sizes while, unlike many regressors, maintaining a low computational cost. The method has been validated using two different publicly available EEG datasets. An average inter-subject validation accuracy of 98.10% is obtained for the smallest dataset during the classification of ten estimated sub-gestures.

## Contact us

The easiest way to get in touch is via our [GitHub issues](https://github.com/AliciaFalconCaro/DABesselMotorDetection/issues).

You are also welcome to email us at [aliciafalconcaro@gmail.com](aliciafalconcaro@gmail.com), to discuss this project, make suggestions, or just say "Hi"!


[1] Falcon-Caro, A., Ferreira, J. F. & Sanei, S. (2024). Cooperative Classification of Prolonged Movement from EEG for BCI without Feedback.
[2] Barnett, L. and Seth,A. K. (2015). Granger causality for state-space models, Phys. Rev. E 91(4) Rapid Communication.
