import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_end_gui/views/cubit/RegisterCubit.dart';
import 'package:front_end_gui/views/widgets/Custom_Text_FormField.dart';
import 'package:front_end_gui/views/SignUp_screen.dart';

/// Pantalla creada para mostrar al usuario el login a la aplicación
/// Vista formada por widget con orden en forma de columna, en el cual se le
/// incrustan 'cajas' y el widget dinámico RegisterForm
class RegisterView extends StatelessWidget {
 
  const RegisterView({super.key});
  

  @override
  Widget build(BuildContext context) {

    //double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return  Scaffold(

      //appBar: AppBar(title: const Text('Nuevo usuario'),),
      body: BlocProvider( // Inyecta el cubic en el árbol de widgets y permite que los hijos accedan
        create:  (context) => RegisterCubit(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:10),
          child: SingleChildScrollView( // Define que hijos pueden acceder al cubit
            child: SizedBox(
              //height: Me,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.black,
                      )
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/imagen1.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        
                      ),
                    ),
                  ),
                  //(height: 5),
                  RegisterForm(),
                  SizedBox(height: screenHeight * 0.01),
                 
                ],
              ),
            ),
          ),
        ),
      )
    );
  }


}


class RegisterForm extends StatelessWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final registerCubit = context.watch<RegisterCubit>(); // Escucha los cambio sy se reconstruye automaticamente
    final email = registerCubit.state.email;
    final password = registerCubit.state.password;
    final isLoading = registerCubit.state.formStatus == FormStatus.validating;
    //final bool mododark = Theme.of(context).brightness == Brightness.light;
    final bool modoDark = Theme.of(context).brightness == Brightness.dark;
    final bool stateForm = registerCubit.state.isValid == true; 
    
    return Form(

      child: Column(
        children: [
          SizedBox(height: screenWidth * 0.08),
          SizedBox(
            child: CustomTextFormfield(
              
              //erroreMessage: 'Este campo necesita ayuda',
              //Icons.person_outline    - Icons.account_circle - 
              prefixIcon:  Icons.account_circle,
              label: 'Correo electrónico',
              onChanged: (value) {
                registerCubit.emailChanged(value);
              },
              //hintText: 'usuario@gmail.com', 
              erroreMessage: email.errorMessage,
              obscureText: false,),
          ),
          SizedBox(height: screenWidth * 0.02),
    
          CustomTextFormfield(
            
            prefixIcon: Icons.lock,
            label: 'Contraseña', 
            onChanged: (value) {
              registerCubit.passwordChanged(value);
            },
            //hintText: 'Contraseña', 
            erroreMessage: password.errorMessage, // En este widget no va a haber validación password
            obscureText: true,),
          SizedBox(height: screenWidth * 0.05),


          SizedBox(
            height: screenHeight * 0.054,
            width: screenWidth * 0.5,
            
            child: FilledButton.tonalIcon(
              onPressed: stateForm && !isLoading
                ? () async {
                    final success = await registerCubit.onSubmit();
                    if (success && context.mounted) {
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Registro exitoso! Por favor inicia sesión.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Navigate back to login screen
                      Navigator.pop(context);
                    } else if (context.mounted) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error en el registro. Por favor, inténtalo de nuevo.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,

              label: isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0, strokeAlign: BorderSide.strokeAlignInside,) 
                :  Text('Iniciar sesión', style: TextStyle( fontSize: screenWidth * 0.045)),
              ),
          ),

          SizedBox(height: screenWidth * 0.02 ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  
                  context,
                  MaterialPageRoute(builder: (context) => SignupForm())
                );
              },
              child: Text(
              '¿No tienes cuenta? Registrate', 
              style: TextStyle(
                color: modoDark ? Colors.black : Colors.white,
                fontSize: screenHeight * 0.02,
                decoration:  TextDecoration.underline,
                decorationThickness: 1,
                decorationColor: modoDark ? Colors.black : Colors.white
                
                
              ),),
            )
          ),

        ],
      ));
  }
}


