//! Observations of the Roadster's public wheel ports.
fn outputs(wheel,names) {
    let values=#{};
    for port in query("ReadPorts",#{api_id:wheel,port_names:names}).ports {
        if port.direction=="out" {values[port.name]=port.value;}
    }
    for name in names {
        if values[name]==() {throw("Missing wheel output "+name+" on "+wheel.to_string());}
    }
    values
}
fn contact(wheel) {outputs(wheel,["contact"]).contact>0.5}
fn contact_count(root) {
    let count=0;
    for corner in ["FL","FR","RL","RR"] {
        if contact(find_path(root+"/Wheel_"+corner)) {count+=1;}
    }
    count
}
