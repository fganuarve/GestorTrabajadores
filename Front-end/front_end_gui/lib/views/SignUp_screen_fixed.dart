import 'package:flutter/material.dart';
import 'package:front_end_gui/views/RegisterView_screen.dart';
import 'package:front_end_gui/views/cubit/SignUpCubit.dart';
import 'package:front_end_gui/views/cubit/SignUpCubit2.dart';
import 'package:front_end_gui/views/cubit/SignUpState2.dart';
import 'package:front_end_gui/views/widgets/AllForms.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/views/Home_screen.dart';
import 'dart:developer' as developer;

class SignupForm extends StatelessWidget {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AllProfesionalFormField(),
    );
  }
}

class AllProfesionalFormField extends StatefulWidget {
  const AllProfesionalFormField({super.key});
  @override
  _AllProfesionalFormField createState() => _AllProfesionalFormField();
}

class _AllProfesionalFormField extends State<AllProfesionalFormField> {
  int _currentStep = 0;
  int _pasos = 1;
  bool? changedStateSpinner;
  bool? isLoading3;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _pasos++;
        if (_pasos == 3) {
          changedStateSpinner = true;
          isLoading3 = false;
        }
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pasos--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpCubit = context.watch<SignUpCubit>();
    final signUpCubit2 = context.watch<SignUpCubit2>();
    final state = signUpCubit.state;
    final state2 = signUpCubit2.state;
    
    bool stateForm = state.isValid;
    bool stateForm2 = state2.isValid2;
    bool stateForm3 = state2.isValid3;

    return Material(
      child: BlocListener<SignUpCubit2, SignUpState2>(
        listener: (context, state) {
          if (state.formStatus3 == FormStatus3.validating) {
            // Mostrar indicador de carga
          }
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _prevStep,
            onStepTapped: (step) {
              setState(() {
                _currentStep = step;
                _pasos = step + 1;
              });
            },
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (_currentStep != 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Atrás'),
                          ),
                        ),
                      if (_currentStep != 0) const SizedBox(width: 15),
                      if (_currentStep < 2)
                        Expanded(
                          child: FilledButton(
                            onPressed: stateForm2 ? details.onStepContinue : null,
                            child: const Text('Siguiente'),
                          ),
                        )
                      else
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: stateForm3 && !(isLoading3 ?? false)
                                ? () async {
                                    try {
                                      setState(() => isLoading3 = true);
                                      
                                      // Ejecutar validaciones
                                      signUpCubit.onSubmit(1);
                                      signUpCubit2.onSubmit2(1);
                                      
                                      // Esperar por el resultado del registro
                                      final success = await signUpCubit2.onSubmit3(1, context);
                                      
                                      if (mounted && success) {
                                        // Mostrar mensaje de éxito
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('¡Registro exitoso! Redirigiendo...'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        
                                        // Navegar de vuelta a la pantalla de login después de un breve retraso
                                        await Future.delayed(const Duration(seconds: 2));
                                        
                                        if (mounted) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (context) => const RegisterView()),
                                            (Route<dynamic> route) => false,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      developer.log('Error durante el registro: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => isLoading3 = false);
                                      }
                                    }
                                  }
                                : null,
                            label: (isLoading3 ?? false)
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Finalizar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
            steps: <Step>[
              Step(
                title: const Text('Datos personales'),
                content: const PersonalFirstForm(),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Datos profesionales'),
                content: const ProfesionalFirstForm(),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Crear cuenta'),
                content: const CreateUserForm(),
                isActive: _currentStep >= 2,
                state: StepState.indexed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
