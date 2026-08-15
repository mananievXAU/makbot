package cmd

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/spf13/cobra"
	//"github.com/stianeikeland/go-rpio/v4"
	telebot "gopkg.in/telebot.v4"
)

var (
	// TeleToken bot
	TeleToken = os.Getenv("TELE_TOKEN")
)

// TrafficSignal represents a single traffic light signal
type TrafficSignal struct {
	Pin int8
	On  bool
}

// kbotCmd represents the kbot command
var kbotCmd = &cobra.Command{
	Use:     "kbot",
	Aliases: []string{"start"},
	Short:   "Telegram bot",
	Long: `A Telegram
	Usage:
  		hello     - Get a greeting from the bot`,
	Run: func(cmd *cobra.Command, args []string) {
		if TeleToken == "" {
			log.Fatal("TELE_TOKEN environment variable is not set")
		}

		fmt.Printf("kbot %s started\n", appVersion)

		kbot, err := telebot.NewBot(telebot.Settings{
			URL:    "",
			Token:  TeleToken,
			Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
		})

		if err != nil {
			log.Fatalf("Please check TELE_TOKEN env variable. %s", err)
		}

		kbot.Handle(telebot.OnText, func(m telebot.Context) error {
			msg := strings.ToLower(m.Message().Payload)

			switch msg {
			case "hello":
				return m.Send("Hi!")
			default:
				return m.Send("???")
			}
		})

		kbot.Start()
	},
}

func init() {
	rootCmd.AddCommand(kbotCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// kbotCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// kbotCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
