package main

import (
    "fmt"
    "flag"
    "net/http"
    "os/exec"
    "time"
    log "github.com/sirupsen/logrus"
    logConfig "vpn-script-daemon/log"
)

var (
    scritpPath  string
    port string
    address string
    http_message string
    http_response int
)

func init() {
    flag.StringVar(&scritpPath, "s", "vpn-create-config.sh", "which vpn script to run")
    flag.StringVar(&address, "address", "0.0.0.0", "address to bind")
    flag.StringVar(&port, "port", "8080", "port number")
    logConfig.InitializeLogging("vpn-script-daemon.log")
}

func check(w http.ResponseWriter, r *http.Request) {


    if r.URL.Path != "/check" {
            http.NotFound(w, r)
            return
    }
    switch r.Method {
    case "GET":

            http_message = fmt.Sprintf("Healthy - OK")
            http_response = http.StatusOK


            w.WriteHeader(http_response)
            w.Write([]byte(http_message))
            log.Infof("Checking healt")

   default:

            w.WriteHeader(http.StatusNotImplemented)
            w.Write([]byte(http.StatusText(http.StatusNotImplemented)))
   }
}
func runScript(w http.ResponseWriter, r *http.Request) {


    if r.URL.Path != "/" {
            http.NotFound(w, r)
            return
    }
    switch r.Method {
    case "GET":

            var arg_action string = "-h"
            var arg_mail string
            var arg_user string
            var exit_code int
            var argument_not_defined int = 0

            script := scritpPath
            query := r.URL.Query()
            request_id := time.Now().Unix()
            request_user := query.Get("userName")
            request_action := query.Get("vpnAction")
            request_mail := query.Get("userMail")

            if request_action == "create" {
                arg_action = "-c"
            } else if request_action == "remove" {
                arg_action = "-r"
            } else if arg_action == "" {
                argument_not_defined = 1
            }

            if request_user == "" {
                argument_not_defined = 1
            } else {
                arg_user = fmt.Sprintf("-u %s", request_user)
            }

            if request_mail == "" {
                arg_mail = ""
            } else {
                arg_mail = fmt.Sprintf("-m %s", request_mail)
            }

            if argument_not_defined == 0 {

                args := []string{script, arg_action, arg_user, arg_mail}

                execScript := &exec.Cmd {
                    Path: script,
                    Args: args,
                }

                log.Infof( "start command. id: %d.", request_id )
                log.Infof("Executed string: '%s'", execScript.String() )
                log.Infof("scritpPath:", scritpPath)

                if out, err := execScript.CombinedOutput(); err != nil {
                    http_message = fmt.Sprintf("Command %d not executed.", request_id)
                    http_response = http.StatusInternalServerError
                    log.Errorf("cmd.Run() failed: %s\n", string(out))
                    exit_code = 1
                } else {
                    http_message = fmt.Sprintf("Command %d executed", request_id )
                    http_response = http.StatusOK
                    log.Infof("command output:\n%s\n", string(out))
                    exit_code = 0
                }
            } else {
                http_message = fmt.Sprintf("Required arguments (vpnAction or userName) not defined. request id: %d", request_id)
                http_response = http.StatusBadRequest

            }

            w.WriteHeader(http_response)
            w.Write([]byte(http_message))
            log.Infof( "finish command with code %d. id: %d.", exit_code, request_id )

   default:

            w.WriteHeader(http.StatusNotImplemented)
            w.Write([]byte(http.StatusText(http.StatusNotImplemented)))
   }
}

func main() {
    flag.Parse()

    fmt.Println("scritpPath:", scritpPath)
    addressToBind := fmt.Sprintf("%s:%s", address, port)
    fmt.Println("Bind Address:", addressToBind)

    http.HandleFunc("/", runScript)
    http.HandleFunc("/check", check)
    http.ListenAndServe(addressToBind, nil)
}
