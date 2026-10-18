// Hosts expose either hook-order selection or resolved-record installation.
fn install_one(policy) {
    let id=policy.hook;
    if policy.source == () { return #{hook:id}; }
    let entry=policy.entry;
    let source=policy.source;
    let file=policy.policy_file;
    let deterministic=policy.deterministic;
    let required=policy.required;
    install_manifest_policy(id,entry,source,file,deterministic,required)
}
fn install_policies(policies) {
    let order=[];
    for policy in policies {
        let result=install_one(policy);
        order.push(result);
    }
    order
}
