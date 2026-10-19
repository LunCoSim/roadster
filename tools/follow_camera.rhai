// Twin-scoped camera authoring. The tool lease supplies the exact Twin and
// committed scene generation; the shared owner checks policy authority.
fn replace_policy(ctx) {
    let result=bind_policy("camera.follow","follow_camera",ctx.source);
    if !result.ok {throw result.error;}
    result
}
