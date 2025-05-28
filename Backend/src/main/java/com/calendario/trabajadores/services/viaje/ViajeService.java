package com.calendario.trabajadores.services.viaje;

import com.calendario.trabajadores.mappings.IViajeMapper;
import com.calendario.trabajadores.model.database.EstadoViaje;
import com.calendario.trabajadores.model.database.Usuario;
import com.calendario.trabajadores.model.database.Vehiculo;
import com.calendario.trabajadores.model.database.Viaje;
import com.calendario.trabajadores.model.dto.viaje.CrearEditarViajeResponse;
import com.calendario.trabajadores.model.dto.viaje.CrearViajeRequest;
import com.calendario.trabajadores.model.dto.viaje.EditarViajeRequest;
import com.calendario.trabajadores.model.dto.viaje.ViajeResponse;
import com.calendario.trabajadores.model.errorresponse.GenericResponse;
import com.calendario.trabajadores.model.errorresponse.ErrorResponse;
import com.calendario.trabajadores.repository.usuario.IUsuarioRepository;
import com.calendario.trabajadores.repository.vehiculo.IVehiculoRepository;
import com.calendario.trabajadores.repository.viaje.IViajeRepository;
import org.springframework.stereotype.Service;

import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ViajeService {

    private final IViajeRepository viajeRepository;
    private final IUsuarioRepository usuarioRepository;
    private final IVehiculoRepository vehiculoRepository;
    private final IViajeMapper viajeMapper;

    //Constructor de ViajeService

    public ViajeService(IViajeRepository viajeRepository, IUsuarioRepository usuarioRepository, IVehiculoRepository vehiculoRepository, IViajeMapper viajeMapper) {
        this.viajeRepository = viajeRepository;
        this.usuarioRepository = usuarioRepository;
        this.vehiculoRepository = vehiculoRepository;
        this.viajeMapper = viajeMapper;
    }

    //Crear un viaje
    public GenericResponse<CrearEditarViajeResponse> crearViaje(CrearViajeRequest request) {
        try {
            // Buscamos las entidades conductor y vehiculo en la base de datos
            Optional<Usuario> responseUsuario = usuarioRepository.findById(request.getIdConductor());
            Optional<Vehiculo> responseVehiculo = vehiculoRepository.findById(request.getIdVehiculo());
            
            // Validamos que existan el conductor y el vehículo
            if (responseUsuario.isEmpty()) {
                return new GenericResponse<>();
            }
            if (responseVehiculo.isEmpty()) {
                return new GenericResponse<>();
            }
            
            // Si no están vacíos, obtenemos los objetos
            Usuario conductor = responseUsuario.get();
            Vehiculo vehiculo = responseVehiculo.get();
            
            // Creamos un nuevo viaje con los datos del request y los objetos conductor y vehiculo
            var nuevoViaje = viajeMapper.crearViajeRequestToViaje(request);
            nuevoViaje.setConductor(conductor);
            nuevoViaje.setVehiculo(vehiculo);
            
            // Guardamos el viaje
            Viaje viajeGuardado = viajeRepository.save(nuevoViaje);

            // Convertimos el viaje a DTO para la respuesta
            CrearEditarViajeResponse response = viajeMapper.viajeToCrearEditarViajeResponse(viajeGuardado);
            
            // Creamos la respuesta exitosa
            GenericResponse<CrearEditarViajeResponse> successResponse = new GenericResponse<>();
            successResponse.setData(response);
            return successResponse;
        } catch (Exception e) {
            // Creamos la respuesta de error
            GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
            errorResponse.setError(new ErrorResponse(e.getMessage()));
            return errorResponse;
        }
    }

    // Cambiar el estado de un viaje con validaciones //TODO: REVISAR TOGGLE CAMBIO DE ESTADO
    //public Optional<ViajeResponse> cambiarEstadoViaje(Long idViaje, EstadoViaje nuevoEstado)
    public GenericResponse<CrearEditarViajeResponse> cambiarEstadoViaje(Long idViaje, String action) {
        try {
            // Buscar el viaje por ID
            Optional<Viaje> viajeOptional = viajeRepository.findById(idViaje);

            // Si no existe, retornamos error
            if (viajeOptional.isEmpty()) {
                GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                errorResponse.setError(new ErrorResponse("Viaje no encontrado"));
                return errorResponse;
            }

            Viaje viajeModel = viajeOptional.get();
            EstadoViaje estadoActual = viajeModel.getEstado();
            
            // Validación: no se puede editar un viaje FINALIZADO
            if (estadoActual == EstadoViaje.FINALIZADO) {
                GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                errorResponse.setError(new ErrorResponse("No se puede cambiar el estado de un viaje finalizado"));
                return errorResponse;
            }

            // Determinar el nuevo estado en función de la acción
            EstadoViaje siguienteEstado = estadoActual;
            if ("confirmar".equalsIgnoreCase(action) && estadoActual == EstadoViaje.DISPONIBLE) {
                siguienteEstado = EstadoViaje.EN_CURSO;
            } else if ("finalizar".equalsIgnoreCase(action) && estadoActual == EstadoViaje.EN_CURSO) {
                siguienteEstado = EstadoViaje.FINALIZADO;
            } else {
                GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                errorResponse.setError(new ErrorResponse("Acción no válida o cambio de estado no permitido"));
                return errorResponse;
            }

            // Si el estado actual es el mismo que el siguiente, no hacemos nada
            if (estadoActual == siguienteEstado) {
                GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                errorResponse.setError(new ErrorResponse("El estado ya es el mismo"));
                return errorResponse;
            }

            // Actualizamos el estado del viaje
            viajeModel.setEstado(siguienteEstado);
            // Guardamos los cambios
            Viaje viajeActualizado = viajeRepository.save(viajeModel);

            // Convertimos el viaje actualizado a DTO para la respuesta
            CrearEditarViajeResponse response = viajeMapper.viajeToCrearEditarViajeResponse(viajeActualizado);
            
            // Creamos la respuesta exitosa
            GenericResponse<CrearEditarViajeResponse> successResponse = new GenericResponse<>();
            successResponse.setData(response);
            return successResponse;
        } catch (Exception e) {
            GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
            errorResponse.setError(new ErrorResponse(e.getMessage()));
            return errorResponse;
        }
    }

    //Editar datos de un viaje
    // TODO EDITAR DATOS DE UN VIAJE : añadir validacion de no se peude editar un viaje en curso o finalizado.
    //No se incluye estado porque no debe ser editado por el usuarioL
    public GenericResponse<CrearEditarViajeResponse> editarViaje(Long id, EditarViajeRequest param) {
        try {
            // Buscar el viaje en la base de datos
            Optional<Viaje> viajeOptional = viajeRepository.findById(id);

            // Si no existe, retornamos error
            if (viajeOptional.isEmpty()) {
                GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                errorResponse.setError(new ErrorResponse("Viaje no encontrado"));
                return errorResponse;
            }

            // Obtener el viaje actual
            Viaje viaje = viajeOptional.get();

            // Validación: no se puede editar un viaje que está en curso o finalizado
            if (viaje.getEstado() != EstadoViaje.DISPONIBLE) {
                GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                errorResponse.setError(new ErrorResponse("No se puede editar un viaje en curso o finalizado"));
                return errorResponse;
            }

            // Actualizar solo los campos que no son nulos en el DTO
            if (param.getOrigen() != null) {
                viaje.setOrigen(param.getOrigen());
            }
            if (param.getDestino() != null) {
                viaje.setDestino(param.getDestino());
            }
            if (param.getFechaSalida() != null) {
                viaje.setFecha(param.getFechaSalida());
            }
            if (param.getHoraSalida() != null) {
                viaje.setHora(param.getHoraSalida());
            }
            if (param.getPlazas() != null) {
                viaje.setPlazas(param.getPlazas());
            }

            // Si se está cambiando el conductor, buscamos el nuevo conductor en la base de datos
            if (param.getIdConductor() != null) {
                Optional<Usuario> conductorOptional = usuarioRepository.findById(param.getIdConductor());
                if (conductorOptional.isEmpty()) {
                    GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                    errorResponse.setError(new ErrorResponse("Conductor no encontrado"));
                    return errorResponse;
                }
                viaje.setConductor(conductorOptional.get());
            }

            // Si se está cambiando el vehículo, buscamos el nuevo vehículo en la base de datos
            if (param.getIdVehiculo() != null) {
                Optional<Vehiculo> vehiculoOptional = vehiculoRepository.findById(param.getIdVehiculo());
                if (vehiculoOptional.isEmpty()) {
                    GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
                    errorResponse.setError(new ErrorResponse("Vehículo no encontrado"));
                    return errorResponse;
                }
                viaje.setVehiculo(vehiculoOptional.get());
            }

            // Guardamos los cambios en la base de datos
            Viaje viajeActualizado = viajeRepository.save(viaje);

            // Usamos el Mapper para convertir el viaje actualizado a un DTO de respuesta
            CrearEditarViajeResponse respuesta = viajeMapper.viajeToCrearEditarViajeResponse(viajeActualizado);

            // Creamos la respuesta exitosa
            GenericResponse<CrearEditarViajeResponse> successResponse = new GenericResponse<>();
            successResponse.setData(respuesta);
            return successResponse;

        } catch (Exception e) {
            GenericResponse<CrearEditarViajeResponse> errorResponse = new GenericResponse<>();
            errorResponse.setError(new ErrorResponse(e.getMessage()));
            return errorResponse;
        }
    }


    //Editar viaje pero sin usar tantos if: ************
/*
    public Optional<CrearEditarViajeResponse> editarViaje(Long id, EditarViajeRequest param) {
    // Buscar el viaje en la base de datos
    Optional<Viaje> viajeOptional = viajeRepository.findById(id);

    // Si no existe, retornamos un Optional vacío
    if (viajeOptional.isEmpty()) {
        return Optional.empty();  // Viaje no encontrado
    }

    // Obtener el viaje actual
    Viaje viaje = viajeOptional.get();

    // Validación: no se puede editar un viaje que está en curso o finalizado
    if (viaje.getEstado() != EstadoViaje.DISPONIBLE) {
        return Optional.empty();  // No se puede editar el viaje
    }

    // Mapeo dinámico: Actualizamos solo los campos no nulos usando reflexión TODO: usar una mapper para esto
    actualizarCampo(viaje::setConductor, param.getIdConductor());
    actualizarCampo(viaje::setOrigen, param.getOrigen());
    actualizarCampo(viaje::setDestino, param.getDestino());
    actualizarCampo(viaje::setFecha, param.getFechaSalida());
    actualizarCampo(viaje::setHora, param.getHoraSalida());
    actualizarCampo(viaje::setVehiculo, param.getIdVehiculo());
    actualizarCampo(viaje::setPlazas, param.getPlazas());

    // Guardamos los cambios en la base de datos
    Viaje viajeActualizado = viajeRepository.save(viaje);

    // Usamos el Mapper para convertir el viaje actualizado a un DTO de respuesta
    CrearEditarViajeResponse respuesta = viajeMapper.viajeToCrearEditarViajeResponse(viajeActualizado);

    return Optional.of(respuesta);  // Retornamos el DTO con los datos actualizados
}

// Método auxiliar para actualizar campos solo si el valor no es nulo
private <T> void actualizarCampo(Consumer<T> setter, T value) {
    if (value != null) {
        setter.accept(value);
    }
}
*/


    //Listar todos los viajes (uso para admin) TODO: REVISAR / USAR COOKIES DE SESION
    //Lista todos los viajes y hace filtrado por rol (admin) y por estado del viaje
    public List<CrearEditarViajeResponse> listarViajes(Long usuarioId, String rol, EstadoViaje estado) {
        List<Viaje> viajes;

        // Si el usuario es admin, puede ver todos los viajes con el filtro de estado
        if ("ADMIN".equalsIgnoreCase(rol)) {
            viajes = viajeRepository.findAllViajesByEstado(estado);  // Admin puede ver todos los viajes
        } else {
            // Si es un usuario normal, solo puede ver los viajes de su usuario y filtrados por estado
            viajes = viajeRepository.findViajesByUsuarioAndEstado(usuarioId, estado);
        }

        // Convertimos la lista de Viaje a CrearEditarViajeResponse usando el Mapper
        List<CrearEditarViajeResponse> viajesResponse = viajes.stream()
                .map(viaje -> viajeMapper.viajeToCrearEditarViajeResponse(viaje))  // Usamos el Mapper para convertir a CrearEditarViajeResponse
                .collect(Collectors.toList());

        return viajesResponse;
    }

    //Listar datos viaje
    public Optional<ViajeResponse> listarDatosViaje(Long idViaje) {
        var viajeExists = viajeRepository.findById(idViaje);
        if (viajeExists.isEmpty()) {
            return Optional.empty();
        }
        var viajeTemp = viajeExists.get();
        var respuesta = viajeMapper.viajeToViajeResponse(viajeTemp);
        return Optional.of(respuesta);
    }
    
    // Listar viajes disponibles con filtros opcionales
    public List<CrearEditarViajeResponse> listarViajesDisponibles(String fecha, String origen, String destino) {
        // Obtener todos los viajes disponibles (estado DISPONIBLE)
        List<Viaje> viajes = viajeRepository.findAllViajesByEstado(EstadoViaje.DISPONIBLE);
        
        System.out.println("Total viajes DISPONIBLE: " + viajes.size());
        
        // Aplicar filtros si se proporcionan
        if (fecha != null && !fecha.isEmpty()) {
            System.out.println("Filtrando por fecha: " + fecha);
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            
            viajes = viajes.stream()
                .filter(v -> {
                    if (v.getFecha() == null) return false;
                    String tripDateStr = sdf.format(v.getFecha());
                    return fecha.equals(tripDateStr);
                })
                .peek(v -> System.out.println("Viaje encontrado - ID: " + v.getId() + ", Fecha: " + sdf.format(v.getFecha())))
                .collect(Collectors.toList());
        }
        
        System.out.println("Viajes después de filtrar: " + viajes.size());
        
        // Aplicar filtro de origen si se proporciona
        if (origen != null && !origen.isEmpty()) {
            viajes = viajes.stream()
                .filter(v -> v.getOrigen() != null && v.getOrigen().equalsIgnoreCase(origen))
                .collect(Collectors.toList());
        }
        
        // Aplicar filtro de destino si se proporciona
        if (destino != null && !destino.isEmpty()) {
            viajes = viajes.stream()
                .filter(v -> v.getDestino() != null && v.getDestino().equalsIgnoreCase(destino))
                .collect(Collectors.toList());
        }
        
        // Convertir a DTO de respuesta
        return viajes.stream()
            .map(viaje -> {
                System.out.println("Mapeando viaje ID: " + viaje.getId() + ", Estado: " + viaje.getEstado());
                return viajeMapper.viajeToCrearEditarViajeResponse(viaje);
            })
            .collect(Collectors.toList());
    }
}
