export function handle(event, context, callback) {
  console.log("Hello from func2!");
  return {
    statusCode: 200,
    body: "Hello from func2!",
  };
}
