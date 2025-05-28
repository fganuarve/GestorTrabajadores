package com.calendario.trabajadores.mappings;

import com.calendario.trabajadores.model.database.EventoCalendario;
import com.calendario.trabajadores.model.dto.calendario.CrearEditarEventoResponse;
import com.calendario.trabajadores.model.dto.calendario.CrearEventoRequest;
import com.calendario.trabajadores.model.dto.calendario.EditarEventoRequest;
import com.calendario.trabajadores.model.dto.calendario.EventoDTO;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-05-28T22:52:00+0200",
    comments = "version: 1.6.3, compiler: javac, environment: Java 17.0.12 (Microsoft)"
)
@Component
public class IEventoCalendarioMapperImpl implements IEventoCalendarioMapper {

    @Override
    public CrearEditarEventoResponse eventoToCrearEditarEventoResponse(EventoCalendario evento) {
        if ( evento == null ) {
            return null;
        }

        CrearEditarEventoResponse crearEditarEventoResponse = new CrearEditarEventoResponse();

        crearEditarEventoResponse.setId( evento.getId() );
        crearEditarEventoResponse.setTitulo( evento.getTitulo() );
        crearEditarEventoResponse.setDescripcion( evento.getDescripcion() );
        crearEditarEventoResponse.setInicio( evento.getInicio() );
        crearEditarEventoResponse.setFin( evento.getFin() );
        crearEditarEventoResponse.setDiaCompleto( evento.isDiaCompleto() );

        return crearEditarEventoResponse;
    }

    @Override
    public EventoCalendario crearEventoRequestToEvento(CrearEventoRequest request) {
        if ( request == null ) {
            return null;
        }

        EventoCalendario eventoCalendario = new EventoCalendario();

        eventoCalendario.setTitulo( request.getTitulo() );
        eventoCalendario.setDescripcion( request.getDescripcion() );
        eventoCalendario.setInicio( request.getInicio() );
        eventoCalendario.setFin( request.getFin() );
        eventoCalendario.setDiaCompleto( request.isDiaCompleto() );

        return eventoCalendario;
    }

    @Override
    public EventoCalendario editarEventoRequestToEvento(EditarEventoRequest request) {
        if ( request == null ) {
            return null;
        }

        EventoCalendario eventoCalendario = new EventoCalendario();

        eventoCalendario.setId( request.getId() );
        eventoCalendario.setTitulo( request.getTitulo() );
        eventoCalendario.setDescripcion( request.getDescripcion() );
        eventoCalendario.setInicio( request.getInicio() );
        eventoCalendario.setFin( request.getFin() );
        eventoCalendario.setDiaCompleto( request.isDiaCompleto() );

        return eventoCalendario;
    }

    @Override
    public EventoDTO eventoToEventoDTO(EventoCalendario evento) {
        if ( evento == null ) {
            return null;
        }

        EventoDTO eventoDTO = new EventoDTO();

        eventoDTO.setId( evento.getId() );
        eventoDTO.setTitulo( evento.getTitulo() );
        eventoDTO.setDescripcion( evento.getDescripcion() );
        eventoDTO.setInicio( evento.getInicio() );
        eventoDTO.setFin( evento.getFin() );
        eventoDTO.setDiaCompleto( evento.isDiaCompleto() );

        return eventoDTO;
    }
}
