exports.init = async function init(app)
{
    app.ports.webgl_fix_to_js.subscribe(a =>
        {
            let gl = document.body.children[0].getContext("webgl");
            gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, false);
            gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
            app.ports.webgl_fix_from_js.send(null);
        });
    app.ports.martinsstewart_elm_device_pixel_ratio_to_js.subscribe(a => app.ports.martinsstewart_elm_device_pixel_ratio_from_js.send(window.devicePixelRatio));

    app.ports.user_agent_to_js.subscribe(a => app.ports.user_agent_from_js.send(navigator.platform));
}