package com.calendario.trabajadores.mappings;

import com.calendario.trabajadores.model.database.Usuario;
import com.calendario.trabajadores.model.database.Vehiculo;
import com.calendario.trabajadores.model.database.Viaje;
import com.calendario.trabajadores.model.dto.usuario.UsuarioResponse;
import com.calendario.trabajadores.model.dto.vehiculo.VehiculoDTO;
import com.calendario.trabajadores.model.dto.viaje.CrearEditarViajeResponse;
import com.calendario.trabajadores.model.dto.viaje.CrearViajeRequest;
import com.calendario.trabajadores.model.dto.viaje.ViajeResponse;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-05-28T23:48:42+0200",
    comments = "version: 1.6.3, compiler: Eclipse JDT (IDE) 3.42.0.v20250514-1000, environment: Java 21.0.7 (Eclipse Adoptium)"
)
@Component
public class IViajeMapperImpl implements IViajeMapper {

    @Override
    public CrearEditarViajeResponse viajeToCrearEditarViajeResponse(Viaje viajeGuardado) {
        if ( viajeGuardado == null ) {
            return null;
        }

        CrearEditarViajeResponse crearEditarViajeResponse = new CrearEditarViajeResponse();

        crearEditarViajeResponse.setIdVehiculo( viajeGuardadoVehiculoId( viajeGuardado ) );
        crearEditarViajeResponse.setIdConductor( viajeGuardadoConductorId( viajeGuardado ) );
        crearEditarViajeResponse.setFechaSalida( viajeGuardado.getFecha() );
        crearEditarViajeResponse.setHoraSalida( viajeGuardado.getHora() );
        crearEditarViajeResponse.setDestino( viajeGuardado.getDestino() );
        crearEditarViajeResponse.setFechaCreacion( viajeGuardado.getFechaCreacion() );
        crearEditarViajeResponse.setFechaModificacion( viajeGuardado.getFechaModificacion() );
        crearEditarViajeResponse.setOrigen( viajeGuardado.getOrigen() );
        crearEditarViajeResponse.setPlazas( viajeGuardado.getPlazas() );

        return crearEditarViajeResponse;
    }

    @Override
    public Viaje crearViajeRequestToViaje(CrearViajeRequest request) {
        if ( request == null ) {
            return null;
        }

        Viaje viaje = new Viaje();

        viaje.setVehiculo( crearViajeRequestToVehiculo( request ) );
        viaje.setConductor( crearViajeRequestToUsuario( request ) );
        viaje.setFecha( request.getFechaSalida() );
        viaje.setHora( request.getHoraSalida() );
        viaje.setDestino( request.getDestino() );
        viaje.setOrigen( request.getOrigen() );
        if ( request.getPlazas() != null ) {
            viaje.setPlazas( request.getPlazas() );
        }

        return viaje;
    }

    @Override
    public ViajeResponse viajeToViajeResponse(Viaje viajedb) {
        if ( viajedb == null ) {
            return null;
        }

        ViajeResponse viajeResponse = new ViajeResponse();

        viajeResponse.setPasajeros( mapPasajeros( viajedb.getUsuarioViajes() ) );
        viajeResponse.setCreadoPor( viajedb.getCreadoPor() );
        viajeResponse.setFechaCreacion( viajedb.getFechaCreacion() );
        viajeResponse.setFechaModificacion( viajedb.getFechaModificacion() );
        viajeResponse.setModificadoPor( viajedb.getModificadoPor() );
        viajeResponse.setConductor( usuarioToUsuarioResponse( viajedb.getConductor() ) );
        viajeResponse.setDestino( viajedb.getDestino() );
        viajeResponse.setFecha( viajedb.getFecha() );
        viajeResponse.setHora( viajedb.getHora() );
        viajeResponse.setOrigen( viajedb.getOrigen() );
        viajeResponse.setPlazas( viajedb.getPlazas() );
        viajeResponse.setVehiculo( vehiculoToVehiculoDTO( viajedb.getVehiculo() ) );

        return viajeResponse;
    }

    @Override
    public UsuarioResponse usuarioToUsuarioResponse(Usuario usuario) {
        if ( usuario == null ) {
            return null;
        }

        UsuarioResponse usuarioResponse = new UsuarioResponse();

        usuarioResponse.setId( usuario.getId() );
        usuarioResponse.setCreadoPor( usuario.getCreadoPor() );
        usuarioResponse.setFechaCreacion( usuario.getFechaCreacion() );
        usuarioResponse.setFechaModificacion( usuario.getFechaModificacion() );
        usuarioResponse.setModificadoPor( usuario.getModificadoPor() );
        usuarioResponse.setActivo( usuario.getActivo() );
        usuarioResponse.setApellido1( usuario.getApellido1() );
        usuarioResponse.setApellido2( usuario.getApellido2() );
        usuarioResponse.setCentroTrabajo( usuario.getCentroTrabajo() );
        usuarioResponse.setDisponibilidadHorasExtras( usuario.getDisponibilidadHorasExtras() );
        usuarioResponse.setEmail( usuario.getEmail() );
        usuarioResponse.setLocalidad( usuario.getLocalidad() );
        usuarioResponse.setNombre( usuario.getNombre() );
        usuarioResponse.setPreferenciasHorarias( usuario.getPreferenciasHorarias() );
        usuarioResponse.setPuesto( usuario.getPuesto() );
        usuarioResponse.setRol( usuario.getRol() );
        usuarioResponse.setTelefono( usuario.getTelefono() );

        return usuarioResponse;
    }

    private Long viajeGuardadoVehiculoId(Viaje viaje) {
        Vehiculo vehiculo = viaje.getVehiculo();
        if ( vehiculo == null ) {
            return null;
        }
        return vehiculo.getId();
    }

    private Long viajeGuardadoConductorId(Viaje viaje) {
        Usuario conductor = viaje.getConductor();
        if ( conductor == null ) {
            return null;
        }
        return conductor.getId();
    }

    protected Vehiculo crearViajeRequestToVehiculo(CrearViajeRequest crearViajeRequest) {
        if ( crearViajeRequest == null ) {
            return null;
        }

        Vehiculo vehiculo = new Vehiculo();

        vehiculo.setId( crearViajeRequest.getIdVehiculo() );

        return vehiculo;
    }

    protected Usuario crearViajeRequestToUsuario(CrearViajeRequest crearViajeRequest) {
        if ( crearViajeRequest == null ) {
            return null;
        }

        Usuario usuario = new Usuario();

        usuario.setId( crearViajeRequest.getIdConductor() );

        return usuario;
    }

    protected VehiculoDTO vehiculoToVehiculoDTO(Vehiculo vehiculo) {
        if ( vehiculo == null ) {
            return null;
        }

        VehiculoDTO vehiculoDTO = new VehiculoDTO();

        vehiculoDTO.setCreadoPor( vehiculo.getCreadoPor() );
        vehiculoDTO.setFechaCreacion( vehiculo.getFechaCreacion() );
        vehiculoDTO.setFechaModificacion( vehiculo.getFechaModificacion() );
        vehiculoDTO.setModificadoPor( vehiculo.getModificadoPor() );
        vehiculoDTO.setActivo( vehiculo.getActivo() );
        vehiculoDTO.setId( vehiculo.getId() );
        vehiculoDTO.setMatricula( vehiculo.getMatricula() );
        vehiculoDTO.setModeloCoche( vehiculo.getModeloCoche() );
        vehiculoDTO.setPlazas( vehiculo.getPlazas() );

        return vehiculoDTO;
    }
}
