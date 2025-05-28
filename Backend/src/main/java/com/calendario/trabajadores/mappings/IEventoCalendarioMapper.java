package com.calendario.trabajadores.mappings;

import org.mapstruct.*;
import com.calendario.trabajadores.model.database.EventoCalendario;
import com.calendario.trabajadores.model.dto.calendario.*;

@Mapper(componentModel = "spring")
public interface IEventoCalendarioMapper {

    // Mapea EventoCalendario a CrearEditarEventoResponse (para respuestas genéricas)
    CrearEditarEventoResponse eventoToCrearEditarEventoResponse(EventoCalendario evento);

    // Mapea CrearEventoRequest a entidad EventoCalendario
    @Mapping(target = "id", ignore = true)
    EventoCalendario crearEventoRequestToEvento(CrearEventoRequest request);

    // Mapea EditarEventoRequest a entidad EventoCalendario
    @Mapping(source = "id", target = "id")
    EventoCalendario editarEventoRequestToEvento(EditarEventoRequest request);

    // Mapea EventoCalendario a EventoDTO
    EventoDTO eventoToEventoDTO(EventoCalendario evento);
}